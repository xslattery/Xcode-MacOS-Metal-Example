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

#define CHUNK_LENGTH 32
#define CHUNK_WIDTH  32
#define CHUNK_HEIGHT 16

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

@implementation Chunk {
	id<MTLBuffer> _vertexBuffer;
	id<MTLBuffer> _indexBuffer;
	NSUInteger indexCount;
	
	id<MTLBuffer> _waterVertexBuffer;
	id<MTLBuffer> _waterIndexBuffer;
	NSUInteger waterIndexCount;
}

- (void)generateMeshWithDevice:(nonnull id<MTLDevice>)device {
	const simd::float2 xAxisDirection {-1, 18.0f/27.0f};
	const simd::float2 zAxisDirection { 1, 18.0f/27.0f};
	
	const simd::float2 textureTopLeft {0, 1.0f/512*68};
	const simd::float2 textureBottomRight {1.0f/512*54,	0.0f};

	std::vector<VertexPT> vertexData;
	std::vector<uint32_t> indexData;

	for (size_t y = 0; y < CHUNK_HEIGHT; ++y) {
		for (size_t z = 0; z < CHUNK_WIDTH; ++z) {
			for (size_t x = 0; x < CHUNK_LENGTH; ++x) {
				if (generate_height_data(x, z, 200, 4, 0.5f, 2.5f, 1) * 8.0f > y) {
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
					indexData.insert( indexData.end(), tempIndices, tempIndices+6 );

					VertexPT tempVerts [4] = {
						{{-27.0f+tileBottomMiddlePosition.x,  0.0f+tileBottomMiddlePosition.y, tileDepth},	{textureTopLeft.x, textureBottomRight.y}},
						{{-27.0f+tileBottomMiddlePosition.x, 68.0f+tileBottomMiddlePosition.y, tileDepth},	{textureTopLeft.x, textureTopLeft.y}},
						{{ 27.0f+tileBottomMiddlePosition.x, 68.0f+tileBottomMiddlePosition.y, tileDepth},	{textureBottomRight.x, textureTopLeft.y}},
						{{ 27.0f+tileBottomMiddlePosition.x,  0.0f+tileBottomMiddlePosition.y, tileDepth},	{textureBottomRight.x, textureBottomRight.y}},
					};
					vertexData.insert( vertexData.end(), tempVerts, tempVerts+4 );
				}
			}
		}
	}

	_vertexBuffer = [device newBufferWithBytes:&vertexData[0] length:vertexData.size()*sizeof(VertexPT) options:MTLResourceStorageModeShared];
	_indexBuffer = [device newBufferWithBytes:&indexData[0] length:indexData.size()*sizeof(uint32_t) options:MTLResourceStorageModeShared];
	indexCount = indexData.size();
	
	const simd::float2 waterTextureTopLeft {1.0f/512*54*3, 1.0f/512*68*3};
	const simd::float2 waterTextureBottomRight {1.0f/512*54*4, 1.0f/512*68*2};
	
	std::vector<VertexPT> waterVertexData;
	std::vector<uint32_t> waterIndexData;
	
	for (size_t y = 0; y < CHUNK_HEIGHT; ++y) {
		for (size_t z = 0; z < CHUNK_WIDTH; ++z) {
			for (size_t x = 0; x < CHUNK_LENGTH; ++x) {
				if (generate_height_data(x, z, 200, 4, 0.5f, 2.5f, 1) * 8.0f <= y) {
					float xx = x, yy = y, zz = z;
					
					simd::float2 tileBottomMiddlePosition {0, 0};
					float tileDepth = 0;
					
					tileBottomMiddlePosition = ((xx)*xAxisDirection + (zz)*zAxisDirection) * 27;
					tileBottomMiddlePosition += simd::float2{ 0, 30 } * (yy);
					tileDepth = (xx + zz) - yy*2;
					
					const uint32_t idxP = (uint32_t)waterVertexData.size();
					uint32_t tempIndices [6] = {
						idxP+0, idxP+1, idxP+2,
						idxP+0, idxP+2, idxP+3
					};
					waterIndexData.insert( waterIndexData.end(), tempIndices, tempIndices+6 );
					
					VertexPT tempVerts [4] = {
						{{-27.0f+tileBottomMiddlePosition.x,  0.0f+tileBottomMiddlePosition.y, tileDepth},	{waterTextureTopLeft.x, waterTextureBottomRight.y}},
						{{-27.0f+tileBottomMiddlePosition.x, 68.0f+tileBottomMiddlePosition.y, tileDepth},	{waterTextureTopLeft.x, waterTextureTopLeft.y}},
						{{ 27.0f+tileBottomMiddlePosition.x, 68.0f+tileBottomMiddlePosition.y, tileDepth},	{waterTextureBottomRight.x, waterTextureTopLeft.y}},
						{{ 27.0f+tileBottomMiddlePosition.x,  0.0f+tileBottomMiddlePosition.y, tileDepth},	{waterTextureBottomRight.x, waterTextureBottomRight.y}},
					};
					waterVertexData.insert( waterVertexData.end(), tempVerts, tempVerts+4 );
				}
			}
		}
	}
	
	_waterVertexBuffer = [device newBufferWithBytes:&waterVertexData[0] length:waterVertexData.size()*sizeof(VertexPT) options:MTLResourceStorageModeShared];
	_waterIndexBuffer = [device newBufferWithBytes:&waterIndexData[0] length:waterIndexData.size()*sizeof(uint32_t) options:MTLResourceStorageModeShared];
	waterIndexCount = waterIndexData.size();
}

- (void)renderWallsWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder {
	[commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:VertexInputIndexVertices];
	[commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:indexCount indexType:MTLIndexTypeUInt32 indexBuffer:_indexBuffer indexBufferOffset:0];
}

- (void)renderWaterWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder {
	[commandEncoder setVertexBuffer:_waterVertexBuffer offset:0 atIndex:VertexInputIndexVertices];
	[commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:waterIndexCount indexType:MTLIndexTypeUInt32 indexBuffer:_waterIndexBuffer indexBufferOffset:0];
}

@end
