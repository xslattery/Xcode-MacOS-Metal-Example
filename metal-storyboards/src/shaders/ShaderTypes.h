//
//  ShaderTypes.h
//  metal-storyboards
//
//  Created by Xavier Slattery on 23/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

enum VertexInputIndex {
	VertexInputIndexVertices = 0,
	VertexInputIndexVP = 1,
	VertexInputIndexSpriteData = 2,
};

enum FragmentInputIndex {
	FragmentInputIndexTexture = 0,
};

struct ViewProjectionMatrices {
	simd::float4x4 projectionMatrix;
	simd::float4x4 viewMatrix;
};

struct VertexPC {
	simd::float3 position;
	simd::float4 color;
};

struct VertexPT {
	simd::float3 position;
	simd::float2 textureCoord;
};

struct SpriteData {
	simd::float3 position;
	simd::float4 pad0;
	simd::float4 pad1;
	simd::float4 pad2;
	simd::float4x4 pad3;
	simd::float4x4 pad4;
	simd::float4x4 pad5;
};

#endif /* ShaderTypes_h */
