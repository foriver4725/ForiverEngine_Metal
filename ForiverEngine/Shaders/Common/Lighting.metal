#pragma once

#include "CommonInclude.metal"
#include "ShaderConstants.metal"

struct LightingParams {
    float3 normal;

    float3 sunDirection;
    float3 sunColor;

    float3 ambientColor;
};

float3 PSCalcLighting(LightingParams params) {
    float nDotL = saturate(dot(params.normal, -params.sunDirection));
    float3 sun = params.sunColor * nDotL / PI;

    float3 ambient = params.ambientColor;

    return sun + ambient;
}
