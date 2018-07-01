//
//  Shaders.metal
//  metal-storyboards
//
//  Created by Xavier Slattery on 23/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

struct VertexInputPC {
	float3 position [[attribute(0)]];
	float4 color [[attribute(1)]];
};

struct RasterDataPC {
	float4 clipSpacePosition [[position]];
	float4 color;
};

vertex RasterDataPC vertexShaderPC ( VertexInputPC in [[stage_in]], constant ViewProjectionMatrices *vp [[buffer(VertexInputIndexVP)]]  ) {
	RasterDataPC result;
	
	result.clipSpacePosition = vp->projectionMatrix * vp->viewMatrix * float4(in.position, 1.0);
	result.color = in.color;
	
	return result;
}

fragment float4 fragmentShaderPC ( RasterDataPC input [[stage_in]] ) {
	return input.color;
}

//////////////////////////

struct VertexInputPT {
	float3 position [[attribute(0)]];
	float2 textureCoord [[attribute(1)]];
};

struct RasterDataPT {
	float4 clipSpacePosition [[position]];
	float2 textureCoord;
};

struct FragOutPT {
	float4 color [[color(0)]] ;
	float depth [[depth(less)]];
};

vertex RasterDataPT vertexShaderPT ( VertexInputPT in [[stage_in]], constant ViewProjectionMatrices *vp [[buffer(VertexInputIndexVP)]]  ) {
	RasterDataPT result;
	
	result.clipSpacePosition = vp->projectionMatrix * vp->viewMatrix * float4(in.position, 1.0);
	result.textureCoord = in.textureCoord;
	
	return result;
}

fragment FragOutPT fragmentShaderPT ( RasterDataPT input [[stage_in]], texture2d<half> colorTexture [[texture(FragmentInputIndexTexture0)]] ) {
	FragOutPT result;
	
	constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
	
	const half4 colorSample = colorTexture.sample(textureSampler, input.textureCoord);
	result.color = float4(colorSample);
	
	if (colorSample.a < 0.01) result.depth = 1.0;
	else result.depth = input.clipSpacePosition.z;
	
	return result;
}

//////////////////////////

vertex RasterDataPT vertexShaderComposetPT ( uint vertexID [[vertex_id]], constant VertexPT *verts [[buffer(VertexInputIndexVertices)]], constant ViewProjectionMatrices *vp [[buffer(VertexInputIndexVP)]]  ) {
	RasterDataPT result;
	
	result.clipSpacePosition = vp->projectionMatrix * vp->viewMatrix * float4(verts[vertexID].position, 1.0);
	result.textureCoord = verts[vertexID].textureCoord;
	
	return result;
}

fragment FragOutPT fragmentShaderComposetPT ( RasterDataPT input [[stage_in]], texture2d<half> colorTexture [[texture(FragmentInputIndexTexture0)]], texture2d<float> depthTexture [[texture(FragmentInputIndexTexture1)]], texture2d<float> oldDepthTexture [[texture(FragmentInputIndexTexture2)]] ) {
	FragOutPT result;
	
	constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest);
	const half4 colorSample = colorTexture.sample(textureSampler, input.textureCoord);
	const float4 depthSample = depthTexture.sample(textureSampler, input.textureCoord);
	
	result.depth = depthSample.r;
//	result.color = float4(colorSample);
	
	const float4 oldDepthSample = oldDepthTexture.sample(textureSampler, input.textureCoord);
	float depthDifference = (oldDepthSample.r - depthSample.r);
	if (oldDepthSample.r > 0.99) depthDifference = 0;
	const float4 tintDark = float4(0.2, 0.7, 0.8, 1);
	const float4 tintLight = float4(1, 1, 1, 1);
	const float4 tint = mix(tintLight, tintDark, min(depthDifference / 0.05, 1.0));
	result.color = float4(colorSample.x, colorSample.y, colorSample.z, colorSample.w) * tint;
	
	return result;
}
