//
//  shader.metal
//  UIKitMadness
//
//  Created by Bogdan Petru on 22.03.2023.
//

#include <metal_stdlib>
using namespace metal;


struct VertexData{
    float2 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOutput{
    float4 position [[position]];
    float4 color;
};
vertex VertexOutput basic_vertex(VertexData in [[stage_in]])
{
    VertexOutput ret;
    ret.position = float4(in.position,0.0,1.0);
    ret.color = in.color;
    return ret;
}

fragment float4 basic_fragment(VertexOutput input [[stage_in]])
{
    return input.color;
}
