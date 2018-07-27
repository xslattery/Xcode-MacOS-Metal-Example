//
//  Renderer.m
//  metal-storyboards
//
//  Created by Xavier Slattery on 23/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#import "Renderer.h"
#import "ShaderTypes.h"

@implementation Renderer {
	id<MTLDevice> _device;
	id<MTLCommandQueue> _commandQueue;
}

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device size:(CGSize)size {
	self = [super init];
	if (!self) return self;

	_device = device;
	assert(_device);
	_commandQueue = [_device newCommandQueue];
	
	return self;
}

- (void)resize:(CGSize)size {

}

- (void)renderScene:(nonnull Scene *)scene withView:(nonnull MTKView *)view {
	// Create a new command buffer:
	id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
	commandBuffer.label = @"Command Buffer";
	
	// Render the scene:
	[scene renderWithCommandBuffer:commandBuffer renderPassDescriptor:view.currentRenderPassDescriptor];
	
	// Present the scene to the view:
	[commandBuffer presentDrawable:view.currentDrawable];
	[commandBuffer commit];
}

@end
