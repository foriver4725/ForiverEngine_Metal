#include "Common/CommonInclude.metal"

struct Uniforms
{
    uint isDrawEnabled;
};

struct VSInput
{
    float4 pos [[attribute(0)]];
    float2 uv [[attribute(1)]];
};

struct V2P
{
    float4 pos [[position]];
    float2 uv;
};

struct PSOutput
{
    float4 color [[color(0)]];
};

vertex V2P VSMain(
    VSInput input [[stage_in]]
)
{
    V2P output;

    output.pos = input.pos;
    output.uv = input.uv;

    return output;
}

fragment PSOutput PSMain(
    V2P input [[stage_in]],
    constant Uniforms& uniforms [[buffer(0)]],
    texture2d<float> texture [[texture(0)]],
    sampler textureSampler [[sampler(0)]]
)
{
    PSOutput output;

    output.color =
        uniforms.isDrawEnabled == 0
        ? float4(0, 0, 0, 0)
        : texture.sample(textureSampler, input.uv);

    return output;
}
