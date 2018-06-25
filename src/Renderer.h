//
//  Renderer.h
//  metal-storyboards
//
//  Created by Xavier Slattery on 23/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#pragma once

#import "Scene.h"

@interface Renderer : NSObject

/// @method initWithDevice:
/// @abstract Call to init the renderer.
/// @param device The MTLDevice used for rendering.
/// @param size The new drawable size.
- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device size:(CGSize)size;

/// @method resize:
/// @abstract Call whenever the drawable size of the view has changed.
/// @param size New size to render to in pixels.
- (void)resize:(CGSize)size;

/// @method renderWithDrawable:
/// @abstract Call to render to the passed drawable.
/// @param drawable The MTLDrawable to render to.
/// @param renderPassDescriptor The MTLRenderPassDescriptor to use.
- (void)renderScene:(nonnull Scene *)scene withDrawable:(nonnull id<MTLDrawable>)drawable renderPassDescriptor:(nonnull MTLRenderPassDescriptor *)renderPassDescriptor;

@end
