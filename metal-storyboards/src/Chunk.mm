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
	NSUInteger _indexCount;
	
	id<MTLBuffer> _spriteDataBuffer;
	NSUInteger _spriteCount;
}

- (void)generateMeshWithDevice:(nonnull id<MTLDevice>)device {
	// Setup Single Sprite to be drawn multiple times in different places:
	const simd::float2 textureTopLeft {0, 1.0f/512*68};
	const simd::float2 textureBottomRight {1.0f/512*54,	0.0f};
	uint32_t tempIndices [6] = {
		0, 1, 2,
		0, 2, 3
	};
	VertexPT tempVerts [4] = {
		{{-27.0f,  0.0f, 0},	{textureTopLeft.x, textureBottomRight.y}},
		{{-27.0f, 68.0f, 0},	{textureTopLeft.x, textureTopLeft.y}},
		{{ 27.0f, 68.0f, 0},	{textureBottomRight.x, textureTopLeft.y}},
		{{ 27.0f,  0.0f, 0},	{textureBottomRight.x, textureBottomRight.y}},
	};
	_vertexBuffer = [device newBufferWithBytes:tempVerts length:sizeof(tempVerts)*sizeof(VertexPT) options:MTLResourceStorageModeShared];
	_indexBuffer = [device newBufferWithBytes:tempIndices length:sizeof(tempIndices)*sizeof(uint32_t) options:MTLResourceStorageModeShared];
	_indexCount = sizeof(tempIndices);
	
	//////////////////////////
	
	std::vector<SpriteData> spriteData;
	
	const simd::float2 xAxisDirection {-1, 18.0f/27.0f};
	const simd::float2 zAxisDirection { 1, 18.0f/27.0f};
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
					
					spriteData.push_back(SpriteData{{tileBottomMiddlePosition.x, tileBottomMiddlePosition.y, tileDepth}});
				}
			}
		}
	}
	
	_spriteDataBuffer = [device newBufferWithBytes:&spriteData[0] length:spriteData.size()*sizeof(SpriteData) options:MTLResourceStorageModeShared];
	_spriteCount = spriteData.size();
}

- (void)renderWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder {
	[commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:VertexInputIndexVertices];
	[commandEncoder setVertexBuffer:_spriteDataBuffer offset:0 atIndex:VertexInputIndexSpriteData];
	
	for (size_t i = 0; i < _spriteCount; ++i) {
		[commandEncoder setVertexBufferOffset:i*256 atIndex:VertexInputIndexSpriteData];
		[commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:_indexCount indexType:MTLIndexTypeUInt32 indexBuffer:_indexBuffer indexBufferOffset:0];
	}
}

@end
