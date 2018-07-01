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
};

enum FragmentInputIndex {
	FragmentInputIndexTexture0 = 0,
	FragmentInputIndexTexture1 = 1,
	FragmentInputIndexTexture2 = 2,
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

#endif /* ShaderTypes_h */
