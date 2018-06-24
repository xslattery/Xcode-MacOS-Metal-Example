//
//  Renderer.m
//  metal-storyboards
//
//  Created by Xavier Slattery on 23/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#import "Renderer.h"
#import "ShaderTypes.h"

//static const VertexPC triangleVertices[] = {
//	// 3D positions:        RGBA colors:
//	{ {  0,   -400, 0.9 }, { 1, 0, 0, 1 } },
//	{ { -640,  100, 0.9 }, { 0, 1, 0, 1 } },
//	{ {  640,  100, 0.9 }, { 0, 0, 1, 1 } },
//
//	{ {  250, -250, 0.5 }, { 1, 0, 0, 1 } },
//	{ { -250, -250, 0.5 }, { 0, 1, 0, 1 } },
//	{ { -250,  250, 0.5 }, { 0, 0, 1, 1 } },
//
//	{ {  300, -200, 0.6 }, { 1, 0, 0, 1 } },
//	{ { -200, -200, 0.6 }, { 0, 1, 0, 1 } },
//	{ { -200,  300, 0.6 }, { 0, 0, 1, 1 } },
//};
//
//static const VertexPC secondTriangleVertices[] = {
//	{ {    0, -250, 0.4 }, { 1, 0, 0, 0.5 } },
//	{ {  250,  250, 0.4 }, { 0, 0, 1, 0.5 } },
//	{ {  250, -250, 0.8 }, { 0, 1, 0, 1 } },
//};
//
//static simd::float4x4 orthographic_projection(float r, float l, float t, float b, float n, float f) {
//	return {
//		simd::make_float4( 2.0f/(r-l),    0.0f,        0.0f,       0.0f),
//		simd::make_float4( 0.0f,          2.0f/(t-b),  0.0f,       0.0f),
//		simd::make_float4( 0.0f,          0.0f,       1.0f/(f-n), 0.0f),
//		simd::make_float4((r+l)/(r-l), (t+b)/(t-b), n/(f-n),    1.0f),
//	};
//}

@implementation Renderer {
	id<MTLDevice> _device;
	id<MTLCommandQueue> _commandQueue;
	
//	id<MTLLibrary> _defaultLibrary;
//	
//	id<MTLRenderPipelineState> _renderPipelineState;
//	id<MTLDepthStencilState> _depthStencilState;
//	
//	id<MTLBuffer> _vertexBuffer;
//	
//	float _nearPlane;
//	float _farPlane;
//	simd::float2 _viewportSize;
//	ViewProjectionMatrices _viewProjectionMatrices;
}

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device size:(CGSize)size {
	self = [super init];
	if (!self) return self;
	
	_device = device;
	assert(_device);
	_commandQueue = [_device newCommandQueue];
	
//	_nearPlane = 0.0;
//	_farPlane = 10.0;
//	_viewportSize = {(float)size.width, (float)size.height};
//	_viewProjectionMatrices.projectionMatrix = orthographic_projection(_viewportSize.x / 2.0f, -_viewportSize.x / 2.0f,
//																	   _viewportSize.y / 2.0f, -_viewportSize.y / 2.0f,
//																	   _nearPlane, _farPlane);
//	_viewProjectionMatrices.viewMatrix = matrix_identity_float4x4;
//
//	_defaultLibrary = [_device newDefaultLibrary];
//	assert(_defaultLibrary);
//
//	id<MTLFunction> vertexFunction = [_defaultLibrary newFunctionWithName:@"vertexShaderPC"];
//	id<MTLFunction> fragmentFunction = [_defaultLibrary newFunctionWithName:@"fragmentShaderPC"];
//	assert(vertexFunction);
//	assert(fragmentFunction);
//
//	MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor new];
//	vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
//	vertexDescriptor.attributes[0].bufferIndex = 0;
//	vertexDescriptor.attributes[0].offset = 0;
//	vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4;
//	vertexDescriptor.attributes[1].bufferIndex = 0;
//	vertexDescriptor.attributes[1].offset = sizeof(simd::float3);
//	vertexDescriptor.layouts[0].stride = sizeof(VertexPC);
//	vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
//
//	MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
//	pipelineStateDescriptor.label = @"Renderer Pipeline";
//	pipelineStateDescriptor.vertexDescriptor = vertexDescriptor;
//	pipelineStateDescriptor.vertexFunction = vertexFunction;
//	pipelineStateDescriptor.fragmentFunction = fragmentFunction;
//	pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
//	pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
//	pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
//	pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
//	pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
//	pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
//	pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
//	pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
//	pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
//
//	NSError *error = nil;
//	_renderPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
//	assert(_renderPipelineState);
//
//	MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
//	depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
//	depthStencilDescriptor.depthWriteEnabled = YES;
//
//	_depthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
//
//	_vertexBuffer = [_device newBufferWithBytes:triangleVertices length:sizeof(triangleVertices) options:MTLResourceStorageModeShared];
//	_vertexBuffer.label = @"Triangle Vertex Buffer";
	
	return self;
}

- (void)resize:(CGSize)size {
//	_viewportSize = {(float)size.width, (float)size.height};
//	_viewProjectionMatrices.projectionMatrix = orthographic_projection(_viewportSize.x / 2.0f, -_viewportSize.x / 2.0f,
//																	   _viewportSize.y / 2.0f, -_viewportSize.y / 2.0f,
//																	   _nearPlane, _farPlane);
}

- (void)renderScene:(nonnull Scene *)scene withDrawable:(nonnull id<MTLDrawable>)drawable renderPassDescriptor:(nonnull MTLRenderPassDescriptor *)renderPassDescriptor {
	id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
	commandBuffer.label = @"Command Buffer";
	
	[scene renderWithCommandBuffer:commandBuffer renderPassDescriptor:renderPassDescriptor];
	
//	id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
//	renderEncoder.label = @"Render Encoder";
//
//	[renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, 0, 1.0 }];
//
//	[renderEncoder setRenderPipelineState:_renderPipelineState];
//	[renderEncoder setDepthStencilState:_depthStencilState];
//	[renderEncoder setCullMode:MTLCullModeBack];
//	[renderEncoder setFrontFacingWinding:MTLWindingClockwise];
//
//	[renderEncoder pushDebugGroup:@"First Triangle Drawing"];
//	[renderEncoder setVertexBytes:&_viewProjectionMatrices length:sizeof(ViewProjectionMatrices) atIndex:VertexInputIndexVP];
//	[renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:VertexInputIndexVertices];
//	[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sizeof(triangleVertices)/sizeof(VertexPC)];
//	[renderEncoder popDebugGroup];
//
//	[renderEncoder pushDebugGroup:@"Second triangle Drawing"];
//	[renderEncoder setVertexBytes:&_viewProjectionMatrices length:sizeof(ViewProjectionMatrices) atIndex:VertexInputIndexVP];
//	[renderEncoder setVertexBytes:secondTriangleVertices length:sizeof(secondTriangleVertices) atIndex:VertexInputIndexVertices];
//	[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sizeof(secondTriangleVertices)/sizeof(VertexPC)];
//	[renderEncoder popDebugGroup];
//
//	[renderEncoder endEncoding];
	
	[commandBuffer presentDrawable:drawable];
	[commandBuffer commit];
}

@end
