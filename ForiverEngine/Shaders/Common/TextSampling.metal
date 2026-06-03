#pragma once

#include "CommonInclude.metal"
#include "ShaderConstants.metal"

struct TextSamplingParams
{
    texture2d<float> fontTexture;
    texture2d<uint> textUIDataTexture;
    sampler textureSampler;

    uint2 fontTextureSize;
    uint2 textUIDataSize;
    uint2 pixelPosition;

    uint invalidFontTextureIndex;
    uint fontTextureTextLength;
};

float4 PSSampleText(TextSamplingParams params)
{
    uint2 textUIDataSamplingUV =
        params.pixelPosition / params.fontTextureTextLength;

    if (any(textUIDataSamplingUV >= params.textUIDataSize))
    {
        return float4(0, 0, 0, 0);
    }

    uint4 textUIDataHere =
        params.textUIDataTexture.read(textUIDataSamplingUV);

    uint textUIDataIndexValue = textUIDataHere.a;

    if (textUIDataIndexValue == params.invalidFontTextureIndex)
    {
        return float4(0, 0, 0, 0);
    }

    uint2 fontPixelIndexSize =
        params.fontTextureSize / params.fontTextureTextLength;

    uint2 fontPixelUV =
        uint2(
            textUIDataIndexValue % fontPixelIndexSize.x,
            textUIDataIndexValue / fontPixelIndexSize.x
        ) * params.fontTextureTextLength;

    uint2 fontPixelUVOffset =
        params.pixelPosition % params.fontTextureTextLength;

    float4 font =
        params.fontTexture.read(fontPixelUV + fontPixelUVOffset);

    if (font.a < 0.01)
    {
        return float4(0, 0, 0, 0);
    }

    float3 textUIDataColorValue =
        float3(textUIDataHere.rgb) / 255.0;

    return float4(textUIDataColorValue, 1);
}
