//
//  Scene.m
//  metal-storyboards
//
//  Created by Xavier Slattery on 24/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#import "Scene.h"
#import "ShaderTypes.h"
#import "Chunk.h"
#define STB_IMAGE_IMPLEMENTATION
#import <stb_image.h>

static const VertexPC triangleVertices[] = {
	// 3D Positions:        RGBA Colors:
	{ {  0,   -400, 0.9 }, { 1, 0, 0, 1 } },
	{ { -640,  100, 0.9 }, { 0, 1, 0, 1 } },
	{ {  640,  100, 0.9 }, { 0, 0, 1, 1 } },
	
	{ {  250, -250, 0.5 }, { 1, 0, 0, 1 } },
	{ { -250, -250, 0.5 }, { 0, 1, 0, 1 } },
	{ { -250,  250, 0.5 }, { 0, 0, 1, 1 } },
	
	{ {  300, -200, 0.6 }, { 1, 0, 0, 1 } },
	{ { -200, -200, 0.6 }, { 0, 1, 0, 1 } },
	{ { -200,  300, 0.6 }, { 0, 0, 1, 1 } },
};

static const VertexPT secondTriangleVertices[] = {
	// 3D Positions:     Texture Coords:
	{ {   0,    0, 0 }, { 0, 0 } },
	{ {   0,  250, 0 }, { 0, 1 } },
	{ { 250,    0, 0 }, { 1, 0 } },
};

static simd::float4x4 orthographic_projection(const float& left, const float& right, const float& bottom, const float& top, const float& near, const float& far) {
	float sLength = 1.0f / (right - left);
	float sHeight = 1.0f / (top   - bottom);
	float sDepth  = 1.0f / (far   - near);
	
	simd::float4 P;
	simd::float4 Q;
	simd::float4 R;
	simd::float4 S;
	
	P.x = 2.0f * sLength;
	P.y = 0.0f;
	P.z = 0.0f;
	P.w = 0.0f;
	
	Q.x = 0.0f;
	Q.y = 2.0f * sHeight;
	Q.z = 0.0f;
	Q.w = 0.0f;
	
	R.x = 0.0f;
	R.y = 0.0f;
	R.z = sDepth;
	R.w = 0.0f;
	
	S.x =  (left + right) / (left - right);
	S.y =  (top + bottom) / (bottom - top);
	S.z = -near  * sDepth;
	S.w =  1.0f;
	
	return simd::float4x4(P, Q, R, S);
}

static simd::float4x4 translate(simd::float4x4 matrix, simd::float3 direction) {
	// TODO(Xavier): Redo all of the vector and matrix maths
	// with custom version to avoid situations like this.
	struct TempVec4 { float x, y, z, w; };
	struct TempMat4 { TempVec4 e[4]; };
	TempMat4 result = *(TempMat4 *)&matrix;
	result.e[3].x += direction.x;
	result.e[3].y += direction.y;
	result.e[3].z += direction.z;
	return *(simd::float4x4 *)&result;
}

@implementation Scene {
	id<MTLDevice> _device;
	id<MTLLibrary> _defaultLibrary;
	
	id<MTLRenderPipelineState> _renderPipelineStatePC;
	id<MTLRenderPipelineState> _renderPipelineStatePT;
	id<MTLDepthStencilState> _depthStencilState;
	
	id<MTLBuffer> _vertexBuffer;
	
	id<MTLTexture> _texture;
	
	float _nearPlane;
	float _farPlane;
	simd::float2 _viewportSize;
	ViewProjectionMatrices _viewProjectionMatrices;
	
	Chunk *_chunk;
}

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device size:(CGSize)size {
	self = [super init];
	if (!self) return self;
	
	NSError *error = nil;
	
	_device = device;
	assert(_device);
	
	//////////////////////////////
	
	_nearPlane = 0.0;
	_farPlane = 1000.0;
	_viewportSize = {(float)size.width, (float)size.height};
	_viewProjectionMatrices.projectionMatrix = orthographic_projection(-_viewportSize.x / 2.0f, _viewportSize.x / 2.0f,
																	   0.0f, _viewportSize.y,
																	   _nearPlane, _farPlane);
	_viewProjectionMatrices.viewMatrix = translate(matrix_identity_float4x4, simd::float3{0, 0, 500});
	
	//////////////////////////////
	
	_defaultLibrary = [_device newDefaultLibrary];
	assert(_defaultLibrary);
	
	//////////////////////////////
	
	id<MTLFunction> vertexFunctionPC = [_defaultLibrary newFunctionWithName:@"vertexShaderPC"];
	id<MTLFunction> fragmentFunctionPC = [_defaultLibrary newFunctionWithName:@"fragmentShaderPC"];
	assert(vertexFunctionPC);
	assert(fragmentFunctionPC);

	MTLVertexDescriptor *vertexDescriptorPC = [MTLVertexDescriptor new];
	vertexDescriptorPC.attributes[0].format = MTLVertexFormatFloat3;
	vertexDescriptorPC.attributes[0].bufferIndex = 0;
	vertexDescriptorPC.attributes[0].offset = 0;
	vertexDescriptorPC.attributes[1].format = MTLVertexFormatFloat4;
	vertexDescriptorPC.attributes[1].bufferIndex = 0;
	vertexDescriptorPC.attributes[1].offset = sizeof(simd::float3);
	vertexDescriptorPC.layouts[0].stride = sizeof(VertexPC);
	vertexDescriptorPC.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

	MTLRenderPipelineDescriptor *pipelineStateDescriptorPC = [MTLRenderPipelineDescriptor new];
	pipelineStateDescriptorPC.label = @"Color Renderer Pipeline";
	pipelineStateDescriptorPC.vertexDescriptor = vertexDescriptorPC;
	pipelineStateDescriptorPC.vertexFunction = vertexFunctionPC;
	pipelineStateDescriptorPC.fragmentFunction = fragmentFunctionPC;
	pipelineStateDescriptorPC.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pipelineStateDescriptorPC.colorAttachments[0].blendingEnabled = YES;
	pipelineStateDescriptorPC.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptorPC.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptorPC.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptorPC.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptorPC.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	pipelineStateDescriptorPC.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusBlendAlpha;
	pipelineStateDescriptorPC.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

	_renderPipelineStatePC = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptorPC error:&error];
	assert(_renderPipelineStatePC);
	
	//////////////////////////////
	
	id<MTLFunction> vertexFunctionPT = [_defaultLibrary newFunctionWithName:@"vertexShaderPT"];
	id<MTLFunction> fragmentFunctionPT = [_defaultLibrary newFunctionWithName:@"fragmentShaderPT"];
	assert(vertexFunctionPT);
	assert(fragmentFunctionPT);
	
	MTLVertexDescriptor *vertexDescriptorPT = [MTLVertexDescriptor new];
	vertexDescriptorPT.attributes[0].format = MTLVertexFormatFloat3;
	vertexDescriptorPT.attributes[0].bufferIndex = 0;
	vertexDescriptorPT.attributes[0].offset = 0;
	vertexDescriptorPT.attributes[1].format = MTLVertexFormatFloat2;
	vertexDescriptorPT.attributes[1].bufferIndex = 0;
	vertexDescriptorPT.attributes[1].offset = sizeof(simd::float3);
	vertexDescriptorPT.layouts[0].stride = sizeof(VertexPT);
	vertexDescriptorPT.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
	
	MTLRenderPipelineDescriptor *pipelineStateDescriptorPT = [MTLRenderPipelineDescriptor new];
	pipelineStateDescriptorPT.label = @"Textured Renderer Pipeline";
	pipelineStateDescriptorPT.vertexDescriptor = vertexDescriptorPT;
	pipelineStateDescriptorPT.vertexFunction = vertexFunctionPT;
	pipelineStateDescriptorPT.fragmentFunction = fragmentFunctionPT;
	pipelineStateDescriptorPT.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pipelineStateDescriptorPT.colorAttachments[0].blendingEnabled = YES;
	pipelineStateDescriptorPT.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptorPT.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptorPT.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptorPT.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptorPT.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	pipelineStateDescriptorPT.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusBlendAlpha;
	pipelineStateDescriptorPT.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
	
	_renderPipelineStatePT = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptorPT error:&error];
	assert(_renderPipelineStatePT);
	
	//////////////////////////////
	
	MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
	depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
	depthStencilDescriptor.depthWriteEnabled = YES;
	
	_depthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
	
	//////////////////////////////
	
	_vertexBuffer = [_device newBufferWithBytes:triangleVertices length:sizeof(triangleVertices) options:MTLResourceStorageModeShared];
	_vertexBuffer.label = @"Triangle Vertex Buffer";
	
	//////////////////////////////
	
	NSURL *imageFileLocation = [[NSBundle mainBundle] URLForResource:@"TileMap" withExtension:@"png"];
	int texWidth, texHeight, n;
	stbi_set_flip_vertically_on_load(true);
	uint8_t *bitmap = stbi_load([imageFileLocation.path UTF8String], &texWidth, &texHeight, &n, 4);
	assert(bitmap);
	MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor new];
	textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
	textureDescriptor.width = texWidth;
	textureDescriptor.height = texWidth;
	_texture = [_device newTextureWithDescriptor:textureDescriptor];
	NSUInteger bytesPerRow = 4 * texWidth;
	MTLRegion region = {{0, 0, 0}, {(NSUInteger)texWidth, (NSUInteger)texHeight, 1}};
	[_texture replaceRegion:region
				mipmapLevel:0
				  withBytes:bitmap
				bytesPerRow:bytesPerRow];
	stbi_image_free(bitmap);
	
	//////////////////////////////
	
	_chunk = [Chunk new];
	[_chunk generateMeshWithDevice:_device];
	
	return self;
}

- (void)resize:(CGSize)size {
	_viewportSize = {(float)size.width, (float)size.height};
	_viewProjectionMatrices.projectionMatrix = orthographic_projection(-_viewportSize.x / 2.0f, _viewportSize.x / 2.0f,
																	   0.0f, _viewportSize.y,
																	   _nearPlane, _farPlane);
}

- (void)renderWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer renderPassDescriptor:(nonnull MTLRenderPassDescriptor *)renderPassDescriptor {
	id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
	renderEncoder.label = @"Render Encoder";
	
	[renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, 0, 1.0 }];
	[renderEncoder setDepthStencilState:_depthStencilState];
	[renderEncoder setCullMode:MTLCullModeBack];
	[renderEncoder setFrontFacingWinding:MTLWindingClockwise];
	
	[renderEncoder setRenderPipelineState:_renderPipelineStatePC];
	[renderEncoder setVertexBytes:&_viewProjectionMatrices length:sizeof(ViewProjectionMatrices) atIndex:VertexInputIndexVP];

	[renderEncoder pushDebugGroup:@"Triangle Group Drawing"];
	[renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:VertexInputIndexVertices];
	[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sizeof(triangleVertices)/sizeof(VertexPC)];
	[renderEncoder popDebugGroup];
	
	[renderEncoder setRenderPipelineState:_renderPipelineStatePT];
	[renderEncoder setVertexBytes:&_viewProjectionMatrices length:sizeof(ViewProjectionMatrices) atIndex:VertexInputIndexVP];
	[renderEncoder setFragmentTexture:_texture atIndex:FragmentInputIndexTexture];
	
//	[renderEncoder pushDebugGroup:@"Single Textured Triangle Drawing"];
//	[renderEncoder setVertexBytes:secondTriangleVertices length:sizeof(secondTriangleVertices) atIndex:VertexInputIndexVertices];
//	[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sizeof(secondTriangleVertices)/sizeof(VertexPC)];
//	[renderEncoder popDebugGroup];

	[renderEncoder pushDebugGroup:@"Chunk Drawing"];
	[_chunk renderWithEncoder:renderEncoder];
	[renderEncoder popDebugGroup];
	
	[renderEncoder endEncoding];
}

@end
