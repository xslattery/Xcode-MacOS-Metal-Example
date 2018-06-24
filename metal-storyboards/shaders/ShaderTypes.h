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

struct VertexPC {
	simd::float3 position;
	simd::float4 color;
};

struct ViewProjectionMatrices {
	simd::float4x4 projectionMatrix;
	simd::float4x4 viewMatrix;
};

#endif /* ShaderTypes_h */
