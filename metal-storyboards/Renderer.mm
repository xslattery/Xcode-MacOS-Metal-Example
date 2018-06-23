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
	
	id<MTLLibrary> _defaultLibrary;
	
	id <MTLRenderPipelineState> _renderPipelineState;
	id<MTLDepthStencilState> _depthStencilState;
	
	simd::float2 _viewportSize;
}

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device size:(CGSize)size {
	self = [super init];
	if (!self) return self;
	
	_device = device;
	_commandQueue = [_device newCommandQueue];
	
	_viewportSize = {(float)size.width, (float)size.height};
	
	_defaultLibrary = [_device newDefaultLibrary];
	
	id<MTLFunction> vertexFunction = [_defaultLibrary newFunctionWithName:@"vertexShaderPC"];
	id<MTLFunction> fragmentFunction = [_defaultLibrary newFunctionWithName:@"fragmentShaderPC"];
	assert(vertexFunction);
	assert(fragmentFunction);
	
	MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
	pipelineStateDescriptor.label = @"Renderer Pipeline";
	pipelineStateDescriptor.vertexFunction = vertexFunction;
	pipelineStateDescriptor.fragmentFunction = fragmentFunction;
	pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
	
	NSError *error = nil;
	_renderPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
	assert(_renderPipelineState);
	
	MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
	depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
	depthStencilDescriptor.depthWriteEnabled = YES;
	
	_depthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
	
	return self;
}

- (void)resize:(CGSize)size {
	_viewportSize = {(float)size.width, (float)size.height};
}

static const VertexPC firstTriangleVertices[] = {
	//   3D positions,        RGBA colors
	{ {  250,  -250, 0.5 }, { 1, 0, 0, 1 } },
	{ { -250,  -250, 0.5 }, { 0, 1, 0, 1 } },
	{ { -250,   250, 0.5 }, { 0, 0, 1, 1 } },
};

static const VertexPC secondTriangleVertices[] = {
	//   3D positions,              RGBA colors
	{ {  250+50,  -250+50, 0.6 }, { 1, 0, 0, 1 } },
	{ { -250+50,  -250+50, 0.6 }, { 0, 1, 0, 1 } },
	{ { -250+50,   250+50, 0.6 }, { 0, 0, 1, 1 } },
};

static const VertexPC thirdTriangleVertices[] = {
	//   3D positions,        RGBA colors
	{ {    0,  -250, 0.4 }, { 1, 0, 0, 1 } },
	{ {  250,   250, 0.4 }, { 0, 0, 1, 1 } },
	{ {  250,  -250, 0.8 }, { 0, 1, 0, 1 } },
};


- (void)renderWithDrawable:(nonnull id<MTLDrawable>)drawable renderPassDescriptor:(nonnull MTLRenderPassDescriptor *)renderPassDescriptor {
	id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
	commandBuffer.label = @"Command Buffer";
	
	id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
	renderEncoder.label = @"Render Encoder";
	
	[renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, 0, 1.0 }];
		
	[renderEncoder setRenderPipelineState:_renderPipelineState];
	[renderEncoder setDepthStencilState:_depthStencilState];
	[renderEncoder setCullMode:MTLCullModeBack];
	[renderEncoder setFrontFacingWinding:MTLWindingClockwise];
	
	[renderEncoder pushDebugGroup:@"First Triangle Drawing"];
		[renderEncoder setVertexBytes:firstTriangleVertices length:sizeof(firstTriangleVertices) atIndex:VertexInputIndexVertices];
		[renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:VertexInputIndexViewportSize];
		[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sizeof(firstTriangleVertices)/sizeof(VertexPC)];
	[renderEncoder popDebugGroup];
	
	[renderEncoder pushDebugGroup:@"Second Triangle Drawing"];
		[renderEncoder setVertexBytes:secondTriangleVertices length:sizeof(secondTriangleVertices) atIndex:VertexInputIndexVertices];
		[renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:VertexInputIndexViewportSize];
		[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sizeof(secondTriangleVertices)/sizeof(VertexPC)];
	[renderEncoder popDebugGroup];
	
	[renderEncoder pushDebugGroup:@"Third Triangle Drawing"];
		[renderEncoder setVertexBytes:thirdTriangleVertices length:sizeof(thirdTriangleVertices) atIndex:VertexInputIndexVertices];
		[renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:VertexInputIndexViewportSize];
		[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sizeof(thirdTriangleVertices)/sizeof(VertexPC)];
	[renderEncoder popDebugGroup];
	
	[renderEncoder endEncoding];
	
	[commandBuffer presentDrawable:drawable];
	[commandBuffer commit];
}

@end
