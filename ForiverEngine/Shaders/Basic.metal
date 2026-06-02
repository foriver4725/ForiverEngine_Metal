#include <metal_stdlib>
using namespace metal;

struct VSInput
{
    float4 pos [[attribute(0)]];
    float2 uv [[attribute(1)]];
    float3 normal [[attribute(2)]];
    float3 centerWorldPosition [[attribute(3)]];
    uint texIndex [[attribute(4)]];
};

struct V2P
{
    float4 position [[position]];
    float2 uv;
    float3 normal;
    
    float3 centerWorldPosition;
    uint texIndex;
};

struct Uniforms
{
    float4x4 matrixMVP;
    float4x4 matrixMIT;
};

struct FragmentUniforms
{
    int3 selectingBlockWorldPosition;
    uint isSelectingBlock;
    float4 selectColor;

    float3 directionalLightDirection;
    float4 directionalLightColor;
    float4 ambientLightColor;
};

float PSCheckIsSelectedBlock(
    float3 centerWorldPosition,
    constant FragmentUniforms& uniforms)
{
    if (uniforms.isSelectingBlock == 0)
    {
        return 0.0;
    }

    if (all(abs(centerWorldPosition -
        float3(uniforms.selectingBlockWorldPosition)) < float3(0.01)))
    {
        return 1.0;
    }

    return 0.0;
}

vertex V2P vertex_main(
    VSInput input [[stage_in]],
    constant Uniforms& uniforms [[buffer(1)]])
{
    V2P output;

    output.position = uniforms.matrixMVP * input.pos;

    float3x3 normalMatrix = float3x3(
        uniforms.matrixMIT[0].xyz,
        uniforms.matrixMIT[1].xyz,
        uniforms.matrixMIT[2].xyz
    );

    output.normal = normalMatrix * input.normal;

    output.uv = input.uv;
    output.centerWorldPosition = input.centerWorldPosition;
    output.texIndex = input.texIndex;

    return output;
}

fragment float4 fragment_main(
    V2P input [[stage_in]],
    constant FragmentUniforms& uniforms [[buffer(0)]],
    texture2d_array<float> textureArray [[texture(0)]],
    sampler textureSampler [[sampler(0)]])
{
    // 1枚のテクスチャに2つ分詰め込まれているので、それをアンパック
    const uint odd = input.texIndex & 1;

    const float2 uvReal =
        odd ? input.uv + float2(0.0, 0.5) : input.uv;

    const uint texIndexReal = input.texIndex >> 1;

    float4 color =
        textureArray.sample(
            textureSampler,
            uvReal,
            texIndexReal);

    if (PSCheckIsSelectedBlock(
            input.centerWorldPosition,
            uniforms) > 0.5)
    {
        color.rgb = mix(
            color.rgb,
            uniforms.selectColor.rgb,
            uniforms.selectColor.a);
    }

    /*
    // ライティング（後で戻す用）

    float3 normal = normalize(input.normal);

    float3 lightDir =
        normalize(uniforms.directionalLightDirection);

    float diffuse =
        max(dot(normal, -lightDir), 0.0);

    float3 lightColor =
        uniforms.ambientLightColor.rgb +
        uniforms.directionalLightColor.rgb * diffuse;

    color.rgb *= lightColor;
    */

    return color;
}
