//
//  Chunk.h
//  metal-storyboards
//
//  Created by Xavier Slattery on 24/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#pragma once

#import <Metal/Metal.h>

#define CHUNK_LENGTH 16
#define CHUNK_WIDTH  16
#define CHUNK_HEIGHT 16

@interface Chunk : NSObject

- (void)generateData;

- (void)generateMeshWithDevice:(nonnull id<MTLDevice>)device;

- (void)renderWallsWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder;
- (void)renderFloorsWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder;
- (void)renderWaterWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder;

@end
