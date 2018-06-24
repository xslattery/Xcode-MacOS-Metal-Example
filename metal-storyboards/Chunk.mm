//
//  Chunk.m
//  metal-storyboards
//
//  Created by Xavier Slattery on 24/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#import "Chunk.h"
#import "ShaderTypes.h"
#import <vector>

#define CHUNK_LENGTH 16
#define CHUNK_WIDTH  16
#define CHUNK_HEIGHT 16

@implementation Chunk {
	id<MTLBuffer> _vertexBuffer;
	id<MTLBuffer> _indexBuffer;
	NSUInteger indexCount;
}

- (void)generateMeshWithDevice:(nonnull id<MTLDevice>)device {
	std::vector<VertexPC> vertexData;
	std::vector<uint32_t> indexData;
	
	const uint32_t cz = 0;
	const uint32_t cy = 0;
	const uint32_t cx = 0;
	const float ox = 0;
	const float oy = 0;
	const float oz = 0;
	const float wLength = CHUNK_LENGTH;
	const float wWidth = CHUNK_WIDTH;
	
	const simd::float2 xDir { -1, 18.0f/27.0f };
	const simd::float2 yDir {  1, 18.0f/27.0f };
	
	simd::float2 tl { 0, 			1.0f-1.0f/512*68 };
	simd::float2 br { 1.0f/512*54, 	1.0f };
	
	for (size_t y = 0; y < CHUNK_LENGTH; ++y) {
		for (size_t z = 0; z < 8; ++z) {
			for (size_t x = 0; x < CHUNK_LENGTH; ++x) {
//				float xOffset = x * 20;
//				float zOffset = y * 20;
//				vertexData.push_back({{-10+xOffset,  0+zOffset, 0}, {1.0, 0.0, 0.0, 1.0}});
//				vertexData.push_back({{-10+xOffset, 20+zOffset, 0}, {0.0, 0.0, 1.0, 1.0}});
//				vertexData.push_back({{ 10+xOffset, 20+zOffset, 0}, {0.0, 1.0, 0.0, 1.0}});
//				vertexData.push_back({{ 10+xOffset,  0+zOffset, 0}, {0.0, 1.0, 1.0, 1.0}});
//
//				const uint32_t cIndex = vertexData.size();
//				uint32_t indices[6] = {
//					cIndex+0, cIndex+1, cIndex+2,
//					cIndex+0, cIndex+2, cIndex+3,
//				};
//				indexData.insert(indexData.end(), indices, indices+6);
				
				float xx = x;
				float yy = y;
				float zz = z;
				
				simd::float2 pos {0, 0};
				float zPos = 0;
				
				pos = ( (xx+ox)*xDir + (yy+oy)*yDir ) * 27;
//				zPos = -(xx+ox + yy+oy) + (zz+oz)*2 + 0.1f;
				zPos = (xx + yy) - zz*2;
				
				pos += simd::float2{ 0, 30 } * (zz+oz);

				const uint32_t idxP = (uint32_t)vertexData.size();
				uint32_t tempIndices [6] = {
					idxP+0, idxP+1, idxP+2,
					idxP+0, idxP+2, idxP+3
				};
				indexData.insert( indexData.end(), tempIndices, tempIndices+6 );

				VertexPC tempVerts [4] = {
					{{-27.0f+pos.x,  0.0f+pos.y, zPos},	{(1.0f/16.0f)*xx, (1.0f/16.0f)*yy, (1.0f/16.0f)*zz, 1}}, // tl.x, br.y,
					{{-27.0f+pos.x, 68.0f+pos.y, zPos},	{(1.0f/16.0f)*xx, (1.0f/16.0f)*yy, (1.0f/16.0f)*zz, 1}}, //	tl.x, tl.y,
					{{ 27.0f+pos.x, 68.0f+pos.y, zPos},	{(1.0f/16.0f)*xx, (1.0f/16.0f)*yy, (1.0f/16.0f)*zz, 1}}, // br.x, tl.y,
					{{ 27.0f+pos.x,  0.0f+pos.y, zPos},	{(1.0f/16.0f)*xx, (1.0f/16.0f)*yy, (1.0f/16.0f)*zz, 1}}, // br.x, br.y,
				};
				vertexData.insert( vertexData.end(), tempVerts, tempVerts+4 );
			}
		}
	}
	
	_vertexBuffer = [device newBufferWithBytes:&vertexData[0] length:vertexData.size()*sizeof(VertexPC) options:MTLResourceStorageModeShared];
	_indexBuffer = [device newBufferWithBytes:&indexData[0] length:indexData.size()*sizeof(uint32_t) options:MTLResourceStorageModeShared];
	indexCount = indexData.size();
}

- (void)renderWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder {
	[commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:VertexInputIndexVertices];
	[commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:indexCount indexType:MTLIndexTypeUInt32 indexBuffer:_indexBuffer indexBufferOffset:0];
}

@end
