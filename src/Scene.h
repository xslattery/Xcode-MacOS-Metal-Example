//
//  Scene.h
//  metal-storyboards
//
//  Created by Xavier Slattery on 24/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#pragma once

#import <Metal/Metal.h>

@interface Scene : NSObject

/// @method initWithDevice:
/// @abstract Call to init the scene.
/// @param device The MTLDevice used for rendering.
/// @param size The new drawable size.
- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device size:(CGSize)size;

/// @method resize:
/// @abstract Call whenever the drawable size of the view has changed.
/// @param size New size to render to in pixels.
- (void)resize:(CGSize)size;

/// @method renderWithDrawable:
/// @abstract Call to render with the passed MTLCommandBuffer.
/// @param commandBuffer The MTLCommandBuffer used to render.
/// @param renderPassDescriptor The MTLRenderPassDescriptor to use.
- (void)renderWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer renderPassDescriptor:(nonnull MTLRenderPassDescriptor *)renderPassDescriptor;

@end
