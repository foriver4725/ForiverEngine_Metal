#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position;
    float2 uv;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertex_main(
    uint vertexID [[vertex_id]],
    const device VertexIn* vertices [[buffer(0)]]
) {
    VertexIn v = vertices[vertexID];

    VertexOut out;
    out.position = float4(v.position, 0.0, 1.0);
    out.uv = v.uv;
    return out;
}

fragment float4 fragment_main(
    VertexOut in [[stage_in]],
    texture2d<float> tex [[texture(0)]],
    sampler smp [[sampler(0)]]
) {
    return tex.sample(smp, in.uv);
}
