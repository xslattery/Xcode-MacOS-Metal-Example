//
//  Renderer.h
//  metal-storyboards
//
//  Created by Xavier Slattery on 23/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#import <Metal/Metal.h>

@interface Renderer : NSObject

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device size:(CGSize)size;
- (void)resize:(CGSize)size;
- (void)renderWithDrawable:(nonnull id<MTLDrawable>)drawable renderPassDescriptor:(nonnull MTLRenderPassDescriptor *)renderPassDescriptor;

@end
