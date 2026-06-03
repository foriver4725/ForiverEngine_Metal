#pragma once

#include "CommonInclude.metal"
#include "ShaderConstants.metal"

// ポストプロセスでAAを適用する

struct AAParams
{
    texture2d<float> texture;
    sampler textureSampler;

    float2 uv;
    float2 uvPerPixel;

    float limitLuminance;
    float aaPower;
};

// 輝度を計算する
float CalcLuminance(float4 color)
{
    const float3 luminanceWeights = float3(0.299, 0.587, 0.114);
    return dot(color.rgb, luminanceWeights);
}

// 計算部
// FXAA っぽい何か
float4 PSCalcAA(AAParams params)
{
    float4 pixels[9] =
    {
        params.texture.sample(params.textureSampler, params.uv + params.uvPerPixel * float2(-1, -1)),
        params.texture.sample(params.textureSampler, params.uv + params.uvPerPixel * float2( 0, -1)),
        params.texture.sample(params.textureSampler, params.uv + params.uvPerPixel * float2( 1, -1)),

        params.texture.sample(params.textureSampler, params.uv + params.uvPerPixel * float2(-1,  0)),
        params.texture.sample(params.textureSampler, params.uv + params.uvPerPixel * float2( 0,  0)),
        params.texture.sample(params.textureSampler, params.uv + params.uvPerPixel * float2( 1,  0)),

        params.texture.sample(params.textureSampler, params.uv + params.uvPerPixel * float2(-1,  1)),
        params.texture.sample(params.textureSampler, params.uv + params.uvPerPixel * float2( 0,  1)),
        params.texture.sample(params.textureSampler, params.uv + params.uvPerPixel * float2( 1,  1)),
    };

    float luminances[9] =
    {
        CalcLuminance(pixels[0]),
        CalcLuminance(pixels[1]),
        CalcLuminance(pixels[2]),

        CalcLuminance(pixels[3]),
        CalcLuminance(pixels[4]),
        CalcLuminance(pixels[5]),

        CalcLuminance(pixels[6]),
        CalcLuminance(pixels[7]),
        CalcLuminance(pixels[8]),
    };

    float4 pixelMeans[12] =
    {
        (pixels[0] + pixels[1] + pixels[2]) / 3.0,
        (pixels[3] + pixels[4] + pixels[5]) / 3.0,
        (pixels[6] + pixels[7] + pixels[8]) / 3.0,

        (pixels[0] + pixels[3] + pixels[6]) / 3.0,
        (pixels[1] + pixels[4] + pixels[7]) / 3.0,
        (pixels[2] + pixels[5] + pixels[8]) / 3.0,

        (pixels[0] + pixels[3] + pixels[1]) / 3.0,
        (pixels[6] + pixels[4] + pixels[2]) / 3.0,
        (pixels[7] + pixels[5] + pixels[8]) / 3.0,

        (pixels[2] + pixels[1] + pixels[5]) / 3.0,
        (pixels[0] + pixels[4] + pixels[8]) / 3.0,
        (pixels[3] + pixels[7] + pixels[6]) / 3.0,
    };

    float luminanceMeans[12] =
    {
        (luminances[0] + luminances[1] + luminances[2]) / 3.0,
        (luminances[3] + luminances[4] + luminances[5]) / 3.0,
        (luminances[6] + luminances[7] + luminances[8]) / 3.0,

        (luminances[0] + luminances[3] + luminances[6]) / 3.0,
        (luminances[1] + luminances[4] + luminances[7]) / 3.0,
        (luminances[2] + luminances[5] + luminances[8]) / 3.0,

        (luminances[0] + luminances[3] + luminances[1]) / 3.0,
        (luminances[6] + luminances[4] + luminances[2]) / 3.0,
        (luminances[7] + luminances[5] + luminances[8]) / 3.0,

        (luminances[2] + luminances[1] + luminances[5]) / 3.0,
        (luminances[0] + luminances[4] + luminances[8]) / 3.0,
        (luminances[3] + luminances[7] + luminances[6]) / 3.0,
    };

    float luminanceMeanDiffs[8] =
    {
        abs(luminanceMeans[0] - luminanceMeans[1]),
        abs(luminanceMeans[2] - luminanceMeans[1]),
        abs(luminanceMeans[3] - luminanceMeans[4]),
        abs(luminanceMeans[5] - luminanceMeans[4]),

        abs(luminanceMeans[6] - luminanceMeans[7]),
        abs(luminanceMeans[8] - luminanceMeans[7]),
        abs(luminanceMeans[9] - luminanceMeans[10]),
        abs(luminanceMeans[11] - luminanceMeans[10]),
    };

    int maxDiffIndex = -1;
    float maxDiff = 0.0;

    for (uint i = 0; i < 8; i++)
    {
        if (luminanceMeanDiffs[i] >= params.limitLuminance)
        {
            if (maxDiff < luminanceMeanDiffs[i])
            {
                maxDiff = luminanceMeanDiffs[i];
                maxDiffIndex = int(i);
            }
        }
    }

    if (maxDiffIndex == -1)
    {
        return pixels[4];
    }

    float aaWeight = pow(maxDiff, params.aaPower);

    float4 aa;

    if (maxDiffIndex == 0)
        aa = mix(pixelMeans[0], pixelMeans[1], aaWeight);
    else if (maxDiffIndex == 1)
        aa = mix(pixelMeans[2], pixelMeans[1], aaWeight);
    else if (maxDiffIndex == 2)
        aa = mix(pixelMeans[3], pixelMeans[4], aaWeight);
    else if (maxDiffIndex == 3)
        aa = mix(pixelMeans[5], pixelMeans[4], aaWeight);
    else if (maxDiffIndex == 4)
        aa = mix(pixelMeans[6], pixelMeans[7], aaWeight);
    else if (maxDiffIndex == 5)
        aa = mix(pixelMeans[8], pixelMeans[7], aaWeight);
    else if (maxDiffIndex == 6)
        aa = mix(pixelMeans[9], pixelMeans[10], aaWeight);
    else
        aa = mix(pixelMeans[11], pixelMeans[10], aaWeight);

    return float4(aa.rgb, pixels[4].a);
}
