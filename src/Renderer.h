//
//  Renderer.h
//  metal-storyboards
//
//  Created by Xavier Slattery on 23/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#pragma once

#import "Scene.h"
#import <MetalKit/MetalKit.h>

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
/// @param view The MTLView to render to.
- (void)renderScene:(nonnull Scene *)scene withView:(nonnull MTKView *)view;

@end
