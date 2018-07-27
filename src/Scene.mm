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

static const simd::float2 xAxisDirection { 1, 18.0f/27.0f};
static const simd::float2 zAxisDirection {-1, 18.0f/27.0f};

static const VertexPT quadVertices[] = {
	// 3D Pos:       Tex:
	{ {-1, -1, 0 }, { 0, 1 } },
	{ {-1,  1, 0 }, { 0, 0 } },
	{ { 1, -1, 0 }, { 1, 1 } },
	
	{ { 1, -1, 0 }, { 1, 1 } },
	{ {-1,  1, 0 }, { 0, 0 } },
	{ { 1,  1, 0 }, { 1, 0 } },
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
	
	id<MTLTexture> _waterDepthTexture;
	id<MTLTexture> _waterColorTexture;
	MTLRenderPassDescriptor *_waterRenderPassDescriptor;
	id<MTLRenderPipelineState> _waterRenderPipelineStatePT;
	id<MTLDepthStencilState> _compositOverlayDepthStencilState;

	id<MTLTexture> _chunkDepthTexture;
	id<MTLTexture> _chunkColorTexture;
	MTLRenderPassDescriptor *_chunkRenderPassDescriptor;
	id<MTLRenderPipelineState> _chunkRenderPipelineStatePT;
	id<MTLDepthStencilState> _chunkOverlayDepthStencilState;
	
	id<MTLRenderPipelineState> _chunkRenderPipelineStateCompositePT;
	id<MTLRenderPipelineState> _waterRenderPipelineStateCompositePT;
	ViewProjectionMatrices _compositOverlayViewProjectionMatrices;
	
	Chunk *_chunk;
}


/////////////////////////////////////
- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device size:(CGSize)size {
	self = [super init];
	if (!self) return self;
	
	NSError *error = nil;
	
	_device = device;
	assert(_device);
	
	////////////////////
	
	// Setup the  view and projection matrices
	// for the scene and the overlay:
	
	_nearPlane = 0.0;
	_farPlane = 1000.0;
	_viewportSize = {(float)size.width, (float)size.height};
	_viewProjectionMatrices.projectionMatrix = orthographic_projection(-_viewportSize.x / 2.0f, _viewportSize.x / 2.0f, 0.0f, _viewportSize.y, _nearPlane, _farPlane);
	_viewProjectionMatrices.viewMatrix = translate(matrix_identity_float4x4, simd::float3{0, 0, 500});
	
	_compositOverlayViewProjectionMatrices.projectionMatrix = orthographic_projection(-1.0, 1.0, -1.0, 1.0, _nearPlane, _farPlane);
	_compositOverlayViewProjectionMatrices.viewMatrix = translate(matrix_identity_float4x4, simd::float3{0, 0, 500});
	
	////////////////////
	
	_defaultLibrary = [_device newDefaultLibrary];
	assert(_defaultLibrary);
	
	////////////////////
	
	// Load and attach the shader for position
	// & color vertex meshes to a pipeline:
	
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
	
	////////////////////
	
	// Load and attach the shader for position
	// & texcoord vertex meshes to a pipeline:
	
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
	
	// Create a pipeline specially for the water,
	// because it should not blend with itself:
	
	MTLRenderPipelineDescriptor *waterPipelineStateDescriptorPT = [MTLRenderPipelineDescriptor new];
	waterPipelineStateDescriptorPT.label = @"Water Textured Renderer Pipeline";
	waterPipelineStateDescriptorPT.vertexDescriptor = vertexDescriptorPT;
	waterPipelineStateDescriptorPT.vertexFunction = vertexFunctionPT;
	waterPipelineStateDescriptorPT.fragmentFunction = fragmentFunctionPT;
	waterPipelineStateDescriptorPT.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	waterPipelineStateDescriptorPT.colorAttachments[0].blendingEnabled = NO;
	waterPipelineStateDescriptorPT.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
	waterPipelineStateDescriptorPT.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
	waterPipelineStateDescriptorPT.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
	waterPipelineStateDescriptorPT.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
	waterPipelineStateDescriptorPT.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	waterPipelineStateDescriptorPT.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusBlendAlpha;
	waterPipelineStateDescriptorPT.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
	
	_waterRenderPipelineStatePT = [_device newRenderPipelineStateWithDescriptor:waterPipelineStateDescriptorPT error:&error];
	assert(_waterRenderPipelineStatePT);
	
	//////////////////////////////
	
	// Create a pipeline for rendering the
	// texture overlay that the chunk gets rendered to:
	
	id<MTLFunction> vertexFunctionComposetPT = [_defaultLibrary newFunctionWithName:@"vertexShaderComposetPT"];
	id<MTLFunction> fragmentFunctionChunkComposetPT = [_defaultLibrary newFunctionWithName:@"fragmentShaderChunkComposetPT"];
	assert(vertexFunctionComposetPT);
	assert(fragmentFunctionChunkComposetPT);
	
	MTLRenderPipelineDescriptor *pipelineStateDescriptorChunkCompositePT = [MTLRenderPipelineDescriptor new];
	pipelineStateDescriptorChunkCompositePT.label = @"Water Overlay Renderer Pipeline";
	pipelineStateDescriptorChunkCompositePT.vertexFunction = vertexFunctionComposetPT;
	pipelineStateDescriptorChunkCompositePT.fragmentFunction = fragmentFunctionChunkComposetPT;
	pipelineStateDescriptorChunkCompositePT.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pipelineStateDescriptorChunkCompositePT.colorAttachments[0].blendingEnabled = YES;
	pipelineStateDescriptorChunkCompositePT.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptorChunkCompositePT.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptorChunkCompositePT.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptorChunkCompositePT.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptorChunkCompositePT.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	pipelineStateDescriptorChunkCompositePT.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusBlendAlpha;
	pipelineStateDescriptorChunkCompositePT.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
	
	_chunkRenderPipelineStateCompositePT = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptorChunkCompositePT error:&error];
	if (!_chunkRenderPipelineStateCompositePT) NSLog(@"%@", error);
	assert(_chunkRenderPipelineStateCompositePT);
	
	//////////////////////////////
	
	// Create a pipeline for rendering
	// the water texture overlay:
	
	id<MTLFunction> fragmentFunctionWaterComposetPT = [_defaultLibrary newFunctionWithName:@"fragmentShaderWaterComposetPT"];
	assert(fragmentFunctionWaterComposetPT);
	
	MTLRenderPipelineDescriptor *pipelineStateDescriptorWaterCompositePT = [MTLRenderPipelineDescriptor new];
	pipelineStateDescriptorWaterCompositePT.label = @"Water Overlay Renderer Pipeline";
	pipelineStateDescriptorWaterCompositePT.vertexFunction = vertexFunctionComposetPT;
	pipelineStateDescriptorWaterCompositePT.fragmentFunction = fragmentFunctionWaterComposetPT;
	pipelineStateDescriptorWaterCompositePT.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	pipelineStateDescriptorWaterCompositePT.colorAttachments[0].blendingEnabled = YES;
	pipelineStateDescriptorWaterCompositePT.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptorWaterCompositePT.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptorWaterCompositePT.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptorWaterCompositePT.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptorWaterCompositePT.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	pipelineStateDescriptorWaterCompositePT.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusBlendAlpha;
	pipelineStateDescriptorWaterCompositePT.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
	
	_waterRenderPipelineStateCompositePT = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptorWaterCompositePT error:&error];
	if (!_waterRenderPipelineStateCompositePT) NSLog(@"%@", error);
	assert(_waterRenderPipelineStateCompositePT);
	
	//////////////////////////////
	
	// Create general depth state:
	
	MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
	depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
	depthStencilDescriptor.depthWriteEnabled = YES;
	
	_depthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
	
	//////////////////////////////
	
	// Create special depth state for rendering the water:
	
	MTLDepthStencilDescriptor *waterOverlayDepthStencilDescriptor = [MTLDepthStencilDescriptor new];
	waterOverlayDepthStencilDescriptor.depthCompareFunction = MTLCompareFunctionAlways;
	waterOverlayDepthStencilDescriptor.depthWriteEnabled = YES;
	
	_compositOverlayDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
	
	//////////////////////////////
	
	// Calculate then build a custom mesh to act as
	// backing walls for the special water depth effect:
	
	int xx = 0, zz = CHUNK_WIDTH, yy = 0;
	simd::float2 neg_x_y_0 = ((xx)*xAxisDirection + (zz)*zAxisDirection) * 27;
	neg_x_y_0 += simd::float2{ 0, 30 } * (yy);
	float neg_x_y_0_depth = (xx + zz) - yy*2;
	
	xx = CHUNK_LENGTH, zz = CHUNK_WIDTH, yy = 0;
	simd::float2 mid_x_y_1 = ((xx)*xAxisDirection + (zz)*zAxisDirection) * 27;
	mid_x_y_1 += simd::float2{ 0, 30 } * (yy);
	float mid_x_y_1_depth = (xx + zz) - yy*2;
	
	xx = 0, zz = CHUNK_WIDTH, yy = CHUNK_HEIGHT;
	simd::float2 mid_x_y_2 = ((xx)*xAxisDirection + (zz)*zAxisDirection) * 27;
	mid_x_y_2 += simd::float2{ 0, 30 } * (yy);
	float mid_x_y_2_depth = (xx + zz) - yy*2;
	
	xx = CHUNK_LENGTH, zz = CHUNK_WIDTH, yy = CHUNK_HEIGHT;
	simd::float2 mid_x_y_3 = ((xx)*xAxisDirection + (zz)*zAxisDirection) * 27;
	mid_x_y_3 += simd::float2{ 0, 30 } * (yy);
	float mid_x_y_3_depth = (xx + zz) - yy*2;
	
	const float neg_x = neg_x_y_0.x;
	const float mid_x = mid_x_y_1.x;
	const float pos_x = -neg_x_y_0.x;
	
	const float y_0 = neg_x_y_0.y;
	const float y_1 = mid_x_y_1.y;
	const float y_2 = mid_x_y_2.y;
	const float y_3 = mid_x_y_3.y;
	
	const float d_0 = mid_x_y_2_depth + 1;
	const float d_1 = mid_x_y_3_depth + 1;
	const float d_2 = neg_x_y_0_depth + 1;
	const float d_3 = mid_x_y_1_depth + 1;
	
	const VertexPC triangleVertices[] = {
		// 3D Positions:        RGBA Colors:
		{ { mid_x, y_1, d_3 }, { 0, 0, 0, 1 } },
		{ { neg_x, y_0, d_2 }, { 0, 0, 0, 1 } },
		{ { mid_x, y_3, d_1 }, { 0, 0, 0, 1 } },
		
		{ { neg_x, y_0, d_2 }, { 0, 0, 0, 1 } },
		{ { neg_x, y_2, d_0 }, { 0, 0, 0, 1 } },
		{ { mid_x, y_3, d_1 }, { 0, 0, 0, 1 } },
		
		{ { mid_x, y_1, d_3 }, { 0, 0, 0, 1 } },
		{ { mid_x, y_3, d_1 }, { 0, 0, 0, 1 } },
		{ { pos_x, y_0, d_2 }, { 0, 0, 0, 1 } },
		
		{ { pos_x, y_0, d_2 }, { 0, 0, 0, 1 } },
		{ { mid_x, y_3, d_1 }, { 0, 0, 0, 1 } },
		{ { pos_x, y_2, d_0 }, { 0, 0, 0, 1 } },
	};
	
	_vertexBuffer = [_device newBufferWithBytes:triangleVertices length:sizeof(triangleVertices) options:MTLResourceStorageModeShared];
	_vertexBuffer.label = @"Triangle Vertex Buffer";
	
	//////////////////////////////
	
	// Load the texture used to render the chunk and water:
	
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
	
	// Create color texture for water pass:
	
	MTLTextureDescriptor *waterColorTextureDescriptor =
	[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
													   width:_viewportSize.x
													  height:_viewportSize.y
												   mipmapped:NO];
	
	waterColorTextureDescriptor.resourceOptions = MTLResourceStorageModePrivate;
	waterColorTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
	
	_waterColorTexture = [_device newTextureWithDescriptor:waterColorTextureDescriptor];
	_waterColorTexture.label = @"Water Color";
	
	// Create depth texture for water pass:
	
	MTLTextureDescriptor *waterDepthTextureDescriptor =
	[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
													   width:_viewportSize.x
													  height:_viewportSize.y
												   mipmapped:NO];
	
	waterDepthTextureDescriptor.resourceOptions = MTLResourceStorageModePrivate;
	waterDepthTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
	
	_waterDepthTexture = [_device newTextureWithDescriptor:waterDepthTextureDescriptor];
	_waterDepthTexture.label = @"Water Depth";
	
	// Create render pass descriptor to reuse for water pass:
	
	_waterRenderPassDescriptor = [MTLRenderPassDescriptor new];
	_waterRenderPassDescriptor.colorAttachments[0].texture = _waterColorTexture;
	_waterRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	_waterRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
	
	_waterRenderPassDescriptor.depthAttachment.texture = _waterDepthTexture;
	_waterRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
	_waterRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
	_waterRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
	
	//////////////////////////////
	
	// Create color texture for chunk pass:
	
	MTLTextureDescriptor *chunkColorTextureDescriptor =
	[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
													   width:_viewportSize.x
													  height:_viewportSize.y
												   mipmapped:NO];
	
	chunkColorTextureDescriptor.resourceOptions = MTLResourceStorageModePrivate;
	chunkColorTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
	
	_chunkColorTexture = [_device newTextureWithDescriptor:chunkColorTextureDescriptor];
	_chunkColorTexture.label = @"chunk Color";
	
	// Create depth texture for chunk pass:
	
	MTLTextureDescriptor *chunkDepthTextureDescriptor =
	[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
													   width:_viewportSize.x
													  height:_viewportSize.y
												   mipmapped:NO];
	
	chunkDepthTextureDescriptor.resourceOptions = MTLResourceStorageModePrivate;
	chunkDepthTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
	
	_chunkDepthTexture = [_device newTextureWithDescriptor:chunkDepthTextureDescriptor];
	_chunkDepthTexture.label = @"chunk Depth";
	
	// Create render pass descriptor to reuse for chunk pass:
	
	_chunkRenderPassDescriptor = [MTLRenderPassDescriptor new];
	_chunkRenderPassDescriptor.colorAttachments[0].texture = _chunkColorTexture;
	_chunkRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	_chunkRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
	
	_chunkRenderPassDescriptor.depthAttachment.texture = _chunkDepthTexture;
	_chunkRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
	_chunkRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
	_chunkRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
	
	//////////////////////////////
	
	// Create the chunk that will be rendered:
	
	_chunk = [Chunk new];
	[_chunk generateData];
	[_chunk generateMeshWithDevice:_device];
	
	return self;
}


/////////////////////////////////////
- (void)resize:(CGSize)size {
	_viewportSize = {(float)size.width, (float)size.height};
	_viewProjectionMatrices.projectionMatrix = orthographic_projection(-_viewportSize.x / 2.0f, _viewportSize.x / 2.0f, 0.0f, _viewportSize.y, _nearPlane, _farPlane);
	
	// NOTE(Xavier): Resizing the textures, just involves creating new ones with the correct sizes,
	// this is because ARC will delete the existing ones for us.
	
	// Resize color texture for water pass:
	
	MTLTextureDescriptor *waterColorTextureDescriptor =
	[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
													   width:_viewportSize.x
													  height:_viewportSize.y
												   mipmapped:NO];
	waterColorTextureDescriptor.resourceOptions = MTLResourceStorageModePrivate;
	waterColorTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
	_waterColorTexture = [_device newTextureWithDescriptor:waterColorTextureDescriptor];
	_waterColorTexture.label = @"Water Color";
	
	// Resize depth texture for water pass:
	
	MTLTextureDescriptor *waterDepthTextureDescriptor =
	[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
													   width:_viewportSize.x
													  height:_viewportSize.y
												   mipmapped:NO];
	waterDepthTextureDescriptor.resourceOptions = MTLResourceStorageModePrivate;
	waterDepthTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
	_waterDepthTexture = [_device newTextureWithDescriptor:waterDepthTextureDescriptor];
	_waterDepthTexture.label = @"Water Depth";
	
	_waterRenderPassDescriptor.colorAttachments[0].texture = _waterColorTexture;
	_waterRenderPassDescriptor.depthAttachment.texture = _waterDepthTexture;

	/////////////////////////

	// Resize color texture for chunk pass:
	
	MTLTextureDescriptor *chunkColorTextureDescriptor =
	[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
													   width:_viewportSize.x
													  height:_viewportSize.y
												   mipmapped:NO];
	chunkColorTextureDescriptor.resourceOptions = MTLResourceStorageModePrivate;
	chunkColorTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
	_chunkColorTexture = [_device newTextureWithDescriptor:chunkColorTextureDescriptor];
	_chunkColorTexture.label = @"chunk Color";
	
	// Resize depth texture for chunk pass:
	
	MTLTextureDescriptor *chunkDepthTextureDescriptor =
	[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
													   width:_viewportSize.x
													  height:_viewportSize.y
												   mipmapped:NO];
	chunkDepthTextureDescriptor.resourceOptions = MTLResourceStorageModePrivate;
	chunkDepthTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
	_chunkDepthTexture = [_device newTextureWithDescriptor:chunkDepthTextureDescriptor];
	_chunkDepthTexture.label = @"chunk Depth";
	
	_chunkRenderPassDescriptor.colorAttachments[0].texture = _chunkColorTexture;
	_chunkRenderPassDescriptor.depthAttachment.texture = _chunkDepthTexture;
}


/////////////////////////////////////
- (void)renderWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer renderPassDescriptor:(nonnull MTLRenderPassDescriptor *)renderPassDescriptor {
	//
	// Render Process:
	// 1. Render water to texture.
	// 2. Render chunk & walls to texture.
	// 3. Render the chunk texture to the view.
	// 4. Render the water texture to the view, using the chunk texture as an input for the depth effect.
	//
	
	////////////
	
	// 1. Draw Water to its texture:
	// NOTE(Xavier): In theory this could be done asynchronously
	
	id<MTLRenderCommandEncoder> waterRenderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_waterRenderPassDescriptor];
	waterRenderEncoder.label = @"Water Pass";
	
	[waterRenderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, 0, 1.0 }];
	[waterRenderEncoder setDepthStencilState:_depthStencilState];
	[waterRenderEncoder setCullMode: MTLCullModeBack];
	[waterRenderEncoder setFrontFacingWinding:MTLWindingClockwise];
	
	[waterRenderEncoder pushDebugGroup:@"Chunk Water Drawing"];
	// FIXME(Xavier): If there is no water the program will hault because
	// the Render Pipeline state has to render something.
	// Fix this by first checking if the chunk contains any water.
	[waterRenderEncoder setRenderPipelineState:_waterRenderPipelineStatePT];
	[waterRenderEncoder setVertexBytes:&_viewProjectionMatrices length:sizeof(ViewProjectionMatrices) atIndex:VertexInputIndexVP];
	[waterRenderEncoder setFragmentTexture:_texture atIndex:FragmentInputIndexTexture0];
	[_chunk renderWaterWithEncoder:waterRenderEncoder];
	[waterRenderEncoder popDebugGroup];
	
	[waterRenderEncoder endEncoding];
	
	///////////
	
	// 2. Draw the chunk and its backing walls to its texture:
	// NOTE(Xavier): In theory this could be done asynchronously
	
	id<MTLRenderCommandEncoder> chunkRenderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_chunkRenderPassDescriptor];
	chunkRenderEncoder.label = @"Chunk Pass";
	
	[chunkRenderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, 0, 1.0 }];
	[chunkRenderEncoder setDepthStencilState:_depthStencilState];
	[chunkRenderEncoder setCullMode:MTLCullModeBack];
	[chunkRenderEncoder setFrontFacingWinding:MTLWindingClockwise];
	
	[chunkRenderEncoder setVertexBytes:&_viewProjectionMatrices length:sizeof(ViewProjectionMatrices) atIndex:VertexInputIndexVP];
	
	// Draw Chunk Backing Walls:
	[chunkRenderEncoder pushDebugGroup:@"Chunk Walls Drawing"];
	[chunkRenderEncoder setRenderPipelineState:_renderPipelineStatePC];
	[chunkRenderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:VertexInputIndexVertices];
	[chunkRenderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:12];
	[chunkRenderEncoder popDebugGroup];
	
	// Draw Chunk:
	[chunkRenderEncoder pushDebugGroup:@"Chunk Drawing"];
	[chunkRenderEncoder setRenderPipelineState:_renderPipelineStatePT];
	[chunkRenderEncoder setFragmentTexture:_texture atIndex:FragmentInputIndexTexture0];
	[_chunk renderWallsWithEncoder:chunkRenderEncoder];
	[_chunk renderFloorsWithEncoder:chunkRenderEncoder];
	[chunkRenderEncoder popDebugGroup];
	
	[chunkRenderEncoder endEncoding];
	
	//////////////
	
	id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
	renderEncoder.label = @"Main Render Encoder";
	
	[renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, 0, 1.0 }];
	[renderEncoder setCullMode:MTLCullModeBack];
	[renderEncoder setFrontFacingWinding:MTLWindingClockwise];
	
	// 3. Composit Terrain:
	
	[renderEncoder pushDebugGroup:@"Chunk Composite"];
	[renderEncoder setRenderPipelineState:_chunkRenderPipelineStateCompositePT];
	[renderEncoder setDepthStencilState:_compositOverlayDepthStencilState];
	[renderEncoder setVertexBytes:&_compositOverlayViewProjectionMatrices length:sizeof(ViewProjectionMatrices) atIndex:VertexInputIndexVP];
	[renderEncoder setFragmentTexture:_chunkColorTexture atIndex:FragmentInputIndexTexture0];
	[renderEncoder setFragmentTexture:_chunkDepthTexture atIndex:FragmentInputIndexTexture1];
	[renderEncoder setVertexBytes:quadVertices length:sizeof(quadVertices) atIndex:VertexInputIndexVertices];
	[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sizeof(quadVertices)/sizeof(VertexPT)];
	[renderEncoder popDebugGroup];
	
	// 4. Composite Water On Terrain:
	// NOTE(Xavier): This stage is the reason why the chunk terrain is rendered to a texture.
	// If you use the views drawable texture the results are unstable and produce artifacts.
	// More research into this may be required.
	
	[renderEncoder pushDebugGroup:@"Water Composite"];
	[renderEncoder setRenderPipelineState:_waterRenderPipelineStateCompositePT];
	[renderEncoder setDepthStencilState:_compositOverlayDepthStencilState];
	[renderEncoder setVertexBytes:&_compositOverlayViewProjectionMatrices length:sizeof(ViewProjectionMatrices) atIndex:VertexInputIndexVP];
	[renderEncoder setFragmentTexture:_waterColorTexture atIndex:FragmentInputIndexTexture0];
	[renderEncoder setFragmentTexture:_waterDepthTexture atIndex:FragmentInputIndexTexture1];
	[renderEncoder setFragmentTexture:_chunkDepthTexture atIndex:FragmentInputIndexTexture2];
	[renderEncoder setVertexBytes:quadVertices length:sizeof(quadVertices) atIndex:VertexInputIndexVertices];
	[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sizeof(quadVertices)/sizeof(VertexPT)];
	[renderEncoder popDebugGroup];
	
	[renderEncoder endEncoding];
}

@end
