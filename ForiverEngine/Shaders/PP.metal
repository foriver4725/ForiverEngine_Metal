#include "Common/CommonInclude.metal"
#include "Common/AA.metal"

struct FragmentUniforms
{
    uint2 windowSize;
    float limitLuminance;
    float aaPower;
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

vertex V2P PP_VSMain(
    VSInput input [[stage_in]]
)
{
    V2P output;

    output.pos = input.pos;
    output.uv = input.uv;

    return output;
}

fragment PSOutput PP_PSMain(
    V2P input [[stage_in]],
    constant FragmentUniforms& uniforms [[buffer(0)]],
    texture2d<float> texture [[texture(0)]],
    sampler textureSampler [[sampler(0)]]
)
{
    PSOutput output;

    AAParams aaParams;
    aaParams.texture = texture;
    aaParams.textureSampler = textureSampler;
    aaParams.uv = input.uv;
    aaParams.uvPerPixel = 1.0 / float2(uniforms.windowSize);
    aaParams.limitLuminance = saturate(uniforms.limitLuminance);
    aaParams.aaPower = uniforms.aaPower;

    output.color = PSCalcAA(aaParams);

    return output;
}
