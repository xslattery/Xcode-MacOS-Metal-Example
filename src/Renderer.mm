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
	dispatch_semaphore_t _inFlightSemaphore;
	
	id<MTLDevice> _device;
	id<MTLCommandQueue> _commandQueue;
}

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device size:(CGSize)size {
	self = [super init];
	if (!self) return self;
	
	_inFlightSemaphore = dispatch_semaphore_create(1);
	
	_device = device;
	assert(_device);
	_commandQueue = [_device newCommandQueue];
	
	return self;
}

- (void)resize:(CGSize)size {

}

- (void)renderScene:(nonnull Scene *)scene withDrawable:(nonnull id<MTLDrawable>)drawable renderPassDescriptor:(nonnull MTLRenderPassDescriptor *)renderPassDescriptor {
	
	// Wait to ensure only MaxBuffersInFlight number of frames are getting proccessed
	// by any stage in the Metal pipeline (App, Metal, Drivers, GPU, etc)
	dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
	
	// Create a new command buffer for each render pass to the current drawable
	id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
	commandBuffer.label = @"Command Buffer";
	
	// Add completion hander which signals _inFlightSemaphore when Metal and the GPU has fully
	// finished processing the commands we're encoding this frame.
	__block dispatch_semaphore_t block_sema = _inFlightSemaphore;
	[commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
		 dispatch_semaphore_signal(block_sema);
	}];
	
	[scene renderWithCommandBuffer:commandBuffer renderPassDescriptor:renderPassDescriptor];
	
	[commandBuffer presentDrawable:drawable];
	[commandBuffer commit];
}

@end
