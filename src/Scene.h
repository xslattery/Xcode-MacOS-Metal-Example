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

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device size:(CGSize)size;

- (void)resize:(CGSize)size;

- (void)renderWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer renderPassDescriptor:(nonnull MTLRenderPassDescriptor *)renderPassDescriptor;

@end
