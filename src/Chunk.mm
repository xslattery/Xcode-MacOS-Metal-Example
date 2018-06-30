//
//  Chunk.m
//  metal-storyboards
//
//  Created by Xavier Slattery on 24/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#import "Chunk.h"
#import "ShaderTypes.h"
#import "Perlin.hpp"
#import <vector>

#define CHUNK_LENGTH 16
#define CHUNK_WIDTH  16
#define CHUNK_HEIGHT 16

static const simd::float2 xAxisDirection {-1, 18.0f/27.0f};
static const simd::float2 zAxisDirection { 1, 18.0f/27.0f};

static float generate_height_data ( float xx, float yy, float scale, int octaves, float persistance, float lacunarity, bool power ) {
	if ( scale <= 0 ) scale = 0.0001f;
	if ( octaves < 1 ) octaves = 1;
	if ( persistance > 1 ) persistance = 1;
	if ( persistance < 0 ) persistance = 0;
	if ( lacunarity < 1 ) lacunarity = 1;
	
	float amplitude = 1.0f;
	float frequency = 1.0f;
	float noiseValue = 0.0f;
	
	for ( int i = 0; i < octaves; ++i ) {
		float sampleX = xx / scale * frequency;
		float sampleZ = yy / scale * frequency;
		
		float nv = noise_2d(sampleX, sampleZ);
		
		noiseValue += nv * amplitude;
		
		amplitude *= persistance;
		frequency *= lacunarity;
	}
	
	if ( power ) noiseValue = pow(2.71828182845904523536, noiseValue);
	
	return noiseValue;
}

struct Wall {
	uint16_t contents;
};

struct Floor {
	uint16_t contents;
};

@implementation Chunk {
	Wall *_walls;
	Floor *_floors;
	
	id<MTLBuffer> _wallVertexBuffer;
	id<MTLBuffer> _wallIndexBuffer;
	NSUInteger _wallIndexCount;
	
	id<MTLBuffer> _floorVertexBuffer;
	id<MTLBuffer> _floorIndexBuffer;
	NSUInteger _floorIndexCount;
	
	id<MTLBuffer> _waterVertexBuffer;
	id<MTLBuffer> _waterIndexBuffer;
	NSUInteger _waterIndexCount;
}

- (void)generateData {
	if (_walls != nil) free(_walls);
	if (_floors != nil) free(_floors);
	
	_walls = (Wall *)malloc(sizeof(Wall)*CHUNK_LENGTH*CHUNK_WIDTH*CHUNK_HEIGHT);
	_floors = (Floor *)malloc(sizeof(Floor)*CHUNK_LENGTH*CHUNK_WIDTH*CHUNK_HEIGHT);
	
	for (size_t y = 0; y < CHUNK_HEIGHT; ++y) {
		for (size_t z = 0; z < CHUNK_WIDTH; ++z) {
			for (size_t x = 0; x < CHUNK_LENGTH; ++x) {
				int height = generate_height_data(x, z, 200, 4, 0.5f, 2.5f, 1) * 8.0f;
				if (y < height) {
					_walls[y*(CHUNK_LENGTH*CHUNK_WIDTH) + z*(CHUNK_LENGTH) + x].contents = 1;
				} else {
					_walls[y*(CHUNK_LENGTH*CHUNK_WIDTH) + z*(CHUNK_LENGTH) + x].contents = 0;
				}
				
				if (y < height + 1) {
					_floors[y*(CHUNK_LENGTH*CHUNK_WIDTH) + z*(CHUNK_LENGTH) + x].contents = 1;
				} else {
					_floors[y*(CHUNK_LENGTH*CHUNK_WIDTH) + z*(CHUNK_LENGTH) + x].contents = 0;
				}
			}
		}
	}
	
}

- (void)dealloc {
	if (_walls != nil) free(_walls);
	if (_floors != nil) free(_floors);
}

- (void)generateMeshWithDevice:(nonnull id<MTLDevice>)device {
	[self generateWallMeshWithDevice:device];
	[self generateFloorMeshWithDevice:device];
	[self generateWaterMeshWithDevice:device];
}

- (void)generateWallMeshWithDevice:(nonnull id<MTLDevice>)device {
//	const simd::float2 textureTopLeft {0, 1.0f/512*68};
//	const simd::float2 textureBottomRight {1.0f/512*54,	0.0f};
	const simd::float2 textureTopLeft {1.0f/512*54*4, 1.0f/512*68*3};
	const simd::float2 textureBottomRight {1.0f/512*54*5, 1.0f/512*68*2};
	
	std::vector<VertexPT> vertexData;
	std::vector<uint32_t> indexData;
	
	for (size_t y = 0; y < CHUNK_HEIGHT; ++y) {
		for (size_t z = 0; z < CHUNK_WIDTH; ++z) {
			for (size_t x = 0; x < CHUNK_LENGTH; ++x) {
				if (_walls[y*(CHUNK_LENGTH*CHUNK_WIDTH) + z*(CHUNK_LENGTH) + x].contents != 0) {
					float xx = x, yy = y, zz = z;
					
					simd::float2 tileBottomMiddlePosition {0, 0};
					float tileDepth = 0;
					
					tileBottomMiddlePosition = ((xx)*xAxisDirection + (zz)*zAxisDirection) * 27;
					tileBottomMiddlePosition += simd::float2{ 0, 30 } * (yy);
					tileDepth = (xx + zz) - yy*2 - 0.1f;
					
					const uint32_t idxP = (uint32_t)vertexData.size();
					uint32_t tempIndices [6] = {
						idxP+0, idxP+1, idxP+2,
						idxP+0, idxP+2, idxP+3
					};
					indexData.insert(indexData.end(), tempIndices, tempIndices+6);
					
					VertexPT tempVerts [4] = {
						{{-27.0f+tileBottomMiddlePosition.x,  0.0f+tileBottomMiddlePosition.y, tileDepth},	{textureTopLeft.x, textureBottomRight.y}},
						{{-27.0f+tileBottomMiddlePosition.x, 68.0f+tileBottomMiddlePosition.y, tileDepth},	{textureTopLeft.x, textureTopLeft.y}},
						{{ 27.0f+tileBottomMiddlePosition.x, 68.0f+tileBottomMiddlePosition.y, tileDepth},	{textureBottomRight.x, textureTopLeft.y}},
						{{ 27.0f+tileBottomMiddlePosition.x,  0.0f+tileBottomMiddlePosition.y, tileDepth},	{textureBottomRight.x, textureBottomRight.y}},
					};
					vertexData.insert(vertexData.end(), tempVerts, tempVerts+4);
				}
			}
		}
	}
	
	if (vertexData.size() > 0) {
		_wallVertexBuffer = [device newBufferWithBytes:&vertexData[0] length:vertexData.size()*sizeof(VertexPT) options:MTLResourceStorageModeShared];
		_wallIndexBuffer = [device newBufferWithBytes:&indexData[0] length:indexData.size()*sizeof(uint32_t) options:MTLResourceStorageModeShared];
		_wallIndexCount = indexData.size();
	}
}

- (void)generateFloorMeshWithDevice:(nonnull id<MTLDevice>)device {
	const simd::float2 textureTopLeft {1.0f/512*54*0, 1.0f/512*68*2};
	const simd::float2 textureBottomRight {1.0f/512*54*1, 1.0f/512*68*1};
	
	std::vector<VertexPT> vertexData;
	std::vector<uint32_t> indexData;
	
	for (size_t y = 0; y < CHUNK_HEIGHT; ++y) {
		for (size_t z = 0; z < CHUNK_WIDTH; ++z) {
			for (size_t x = 0; x < CHUNK_LENGTH; ++x) {
				if (_floors[y*(CHUNK_LENGTH*CHUNK_WIDTH) + z*(CHUNK_LENGTH) + x].contents != 0) {
					float xx = x, yy = y, zz = z;
					
					simd::float2 tileBottomMiddlePosition {0, 0};
					float tileDepth = 0;
					
					tileBottomMiddlePosition = ((xx)*xAxisDirection + (zz)*zAxisDirection) * 27;
					tileBottomMiddlePosition += simd::float2{ 0, 30 } * (yy);
					tileDepth = (xx + zz) - yy*2;
					
					const uint32_t idxP = (uint32_t)vertexData.size();
					uint32_t tempIndices [6] = {
						idxP+0, idxP+1, idxP+2,
						idxP+0, idxP+2, idxP+3
					};
					indexData.insert(indexData.end(), tempIndices, tempIndices+6);
					
					VertexPT tempVerts [4] = {
						{{-27.0f+tileBottomMiddlePosition.x,  0.0f+tileBottomMiddlePosition.y, tileDepth},	{textureTopLeft.x, textureBottomRight.y}},
						{{-27.0f+tileBottomMiddlePosition.x, 68.0f+tileBottomMiddlePosition.y, tileDepth},	{textureTopLeft.x, textureTopLeft.y}},
						{{ 27.0f+tileBottomMiddlePosition.x, 68.0f+tileBottomMiddlePosition.y, tileDepth},	{textureBottomRight.x, textureTopLeft.y}},
						{{ 27.0f+tileBottomMiddlePosition.x,  0.0f+tileBottomMiddlePosition.y, tileDepth},	{textureBottomRight.x, textureBottomRight.y}},
					};
					vertexData.insert(vertexData.end(), tempVerts, tempVerts+4);
				}
			}
		}
	}
	
	if (vertexData.size() > 0) {
		_floorVertexBuffer = [device newBufferWithBytes:&vertexData[0] length:vertexData.size()*sizeof(VertexPT) options:MTLResourceStorageModeShared];
		_floorIndexBuffer = [device newBufferWithBytes:&indexData[0] length:indexData.size()*sizeof(uint32_t) options:MTLResourceStorageModeShared];
		_floorIndexCount = indexData.size();
	}
}

- (void)generateWaterMeshWithDevice:(nonnull id<MTLDevice>)device {
	const simd::float2 textureTopLeft {1.0f/512*54*3, 1.0f/512*68*3};
	const simd::float2 textureBottomRight {1.0f/512*54*4, 1.0f/512*68*2};
	
	std::vector<VertexPT> vertexData;
	std::vector<uint32_t> indexData;
	
	for (size_t y = 0; y < CHUNK_HEIGHT; ++y) {
		for (size_t z = 0; z < CHUNK_WIDTH; ++z) {
			for (size_t x = 0; x < CHUNK_LENGTH; ++x) {
				if (_walls[y*(CHUNK_LENGTH*CHUNK_WIDTH) + z*(CHUNK_LENGTH) + x].contents == 0) {
					float xx = x, yy = y, zz = z;
					
					simd::float2 tileBottomMiddlePosition {0, 0};
					float tileDepth = 0;
					
					tileBottomMiddlePosition = ((xx)*xAxisDirection + (zz)*zAxisDirection) * 27;
					tileBottomMiddlePosition += simd::float2{ 0, 30 } * (yy);
					tileDepth = (xx + zz) - yy*2 - 0.1f;
					
					const uint32_t idxP = (uint32_t)vertexData.size();
					uint32_t tempIndices [6] = {
						idxP+0, idxP+1, idxP+2,
						idxP+0, idxP+2, idxP+3
					};
					indexData.insert(indexData.end(), tempIndices, tempIndices+6);
					
					VertexPT tempVerts [4] = {
						{{-27.0f+tileBottomMiddlePosition.x,  0.0f+tileBottomMiddlePosition.y, tileDepth},	{textureTopLeft.x, textureBottomRight.y}},
						{{-27.0f+tileBottomMiddlePosition.x, 68.0f+tileBottomMiddlePosition.y, tileDepth},	{textureTopLeft.x, textureTopLeft.y}},
						{{ 27.0f+tileBottomMiddlePosition.x, 68.0f+tileBottomMiddlePosition.y, tileDepth},	{textureBottomRight.x, textureTopLeft.y}},
						{{ 27.0f+tileBottomMiddlePosition.x,  0.0f+tileBottomMiddlePosition.y, tileDepth},	{textureBottomRight.x, textureBottomRight.y}},
					};
					vertexData.insert(vertexData.end(), tempVerts, tempVerts+4);
				}
			}
		}
	}
	
	if (vertexData.size() > 0) {
		_waterVertexBuffer = [device newBufferWithBytes:&vertexData[0] length:vertexData.size()*sizeof(VertexPT) options:MTLResourceStorageModeShared];
		_waterIndexBuffer = [device newBufferWithBytes:&indexData[0] length:indexData.size()*sizeof(uint32_t) options:MTLResourceStorageModeShared];
		_waterIndexCount = indexData.size();
	}
}

- (void)renderWallsWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder {
	if (_wallVertexBuffer != nil && _wallIndexBuffer != nil) {
		[commandEncoder setVertexBuffer:_wallVertexBuffer offset:0 atIndex:VertexInputIndexVertices];
		[commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:_wallIndexCount indexType:MTLIndexTypeUInt32 indexBuffer:_wallIndexBuffer indexBufferOffset:0];
	}
}

- (void)renderFloorsWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder {
	if (_floorVertexBuffer != nil && _floorIndexBuffer != nil) {
		[commandEncoder setVertexBuffer:_floorVertexBuffer offset:0 atIndex:VertexInputIndexVertices];
		[commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:_floorIndexCount indexType:MTLIndexTypeUInt32 indexBuffer:_floorIndexBuffer indexBufferOffset:0];
	}
}

- (void)renderWaterWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder {
	if (_waterVertexBuffer != nil && _waterIndexBuffer != nil) {
		[commandEncoder setVertexBuffer:_waterVertexBuffer offset:0 atIndex:VertexInputIndexVertices];
		[commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:_waterIndexCount indexType:MTLIndexTypeUInt32 indexBuffer:_waterIndexBuffer indexBufferOffset:0];
	}
}

@end
