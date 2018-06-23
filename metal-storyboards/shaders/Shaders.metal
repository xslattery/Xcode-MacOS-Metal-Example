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

struct RasterDataPC {
	float4 clipSpacePosition [[position]];
	float4 color;
};

vertex RasterDataPC vertexShaderPC ( uint vertexID [[vertex_id]],
									constant VertexPC *vertices [[buffer(VertexInputIndexVertices)]],
									constant float2 *viewportSize [[buffer(VertexInputIndexViewportSize)]] ) {
	RasterDataPC result;
	
	result.clipSpacePosition = float4(0, 0, 0, 1);
	result.clipSpacePosition.xy = vertices[vertexID].position.xy / *viewportSize / 1.0;
	result.clipSpacePosition.z = vertices[vertexID].position.z;
	
	result.color = vertices[vertexID].color;
	
	return result;
}

fragment float4 fragmentShaderPC ( RasterDataPC input [[stage_in]] ) {
	return input.color;
}
