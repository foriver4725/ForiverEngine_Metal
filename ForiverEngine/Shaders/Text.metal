#include "Common/CommonInclude.metal"
#include "Common/TextSampling.metal"

struct FragmentUniforms
{
    uint2 fontTextureSize;
    uint2 textUIDataSize;
    uint invalidFontTextureIndex;
    uint fontTextureTextLength;
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
    constant FragmentUniforms& uniforms [[buffer(0)]],
    texture2d<float> texture [[texture(0)]],
    texture2d<float> fontTexture [[texture(1)]],
    texture2d<uint> textUIDataTexture [[texture(2)]],
    sampler textureSampler [[sampler(0)]]
)
{
    PSOutput output;

    float4 originalColor =
        texture.sample(textureSampler, input.uv);

    TextSamplingParams textSamplingParams;
    textSamplingParams.fontTexture = fontTexture;
    textSamplingParams.textUIDataTexture = textUIDataTexture;
    textSamplingParams.textureSampler = textureSampler;
    textSamplingParams.fontTextureSize = uniforms.fontTextureSize;
    textSamplingParams.textUIDataSize = uniforms.textUIDataSize;
    textSamplingParams.pixelPosition = uint2(input.pos.xy);
    textSamplingParams.invalidFontTextureIndex =
        uniforms.invalidFontTextureIndex;
    textSamplingParams.fontTextureTextLength =
        uniforms.fontTextureTextLength;

    float4 textColor = PSSampleText(textSamplingParams);

    output.color =
        textColor.a > 0.5
        ? textColor
        : originalColor;

    return output;
}
