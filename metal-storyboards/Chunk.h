//
//  Chunk.h
//  metal-storyboards
//
//  Created by Xavier Slattery on 24/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#import <Metal/Metal.h>

@interface Chunk : NSObject

- (void)generateMeshWithDevice:(nonnull id<MTLDevice>)device;

- (void)renderWithEncoder:(nonnull id<MTLRenderCommandEncoder>)commandEncoder;

@end
