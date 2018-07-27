//
//  Chunk.h
//  metal-storyboards
//
//  Created by Xavier Slattery on 24/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#pragma once

#import <Metal/Metal.h>

#define WORLD_X 32
#define WORLD_Z 32
#define WORLD_Y 32

#define CHUNK_LENGTH 32
#define CHUNK_WIDTH  32
#define CHUNK_HEIGHT 32

@interface Chunk : NSObject

- (void)generateData;

- (void)generateMeshWithDevice:(nonnull id<MTLDevice>)device;

- (void)renderWallsWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder;
- (void)renderFloorsWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder;
- (void)renderWaterWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder;

@end
