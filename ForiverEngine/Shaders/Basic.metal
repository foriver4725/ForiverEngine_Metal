#include "Common/CommonInclude.metal"
#include "Common/Lighting.metal"

struct VertexUniforms
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
    float _padding0;

    float4 directionalLightColor;
    float4 ambientLightColor;
};

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
    float4 pos [[position]];
    float2 uv;
    float3 normal;
    float3 centerWorldPosition [[flat]];
    uint texIndex [[flat]];
};

struct PSOutput
{
    float4 color [[color(0)]];
};

float PSCheckIsSelectedBlock(
    float3 centerWorldPosition,
    constant FragmentUniforms& uniforms
)
{
    if (uniforms.isSelectingBlock == 0)
    {
        return 0.0;
    }

    float3 selectingBlockWorldPosition =
        float3(uniforms.selectingBlockWorldPosition);

    if (all(abs(centerWorldPosition - selectingBlockWorldPosition)
        < float3(0.01, 0.01, 0.01)))
    {
        return 1.0;
    }

    return 0.0;
}

vertex V2P VSMain(
    VSInput input [[stage_in]],
    constant VertexUniforms& uniforms [[buffer(1)]]
)
{
    V2P output;

    output.pos = uniforms.matrixMVP * input.pos;
    float3x3 matrixMIT3x3 = float3x3(
        uniforms.matrixMIT[0].xyz,
        uniforms.matrixMIT[1].xyz,
        uniforms.matrixMIT[2].xyz
    );
    output.normal = matrixMIT3x3 * input.normal;

    output.uv = input.uv;
    output.centerWorldPosition = input.centerWorldPosition;
    output.texIndex = input.texIndex;

    return output;
}

fragment PSOutput PSMain(
    V2P input [[stage_in]],
    constant FragmentUniforms& uniforms [[buffer(0)]],
    texture2d_array<float> textureArray [[texture(0)]],
    sampler textureSampler [[sampler(0)]]
)
{
    PSOutput output;

    uint odd = input.texIndex & 1;
    float2 uvReal =
        odd != 0
        ? input.uv + float2(0.0, 0.5)
        : input.uv;

    uint texIndexReal = input.texIndex >> 1;

    float4 color = textureArray.sample(
        textureSampler,
        uvReal,
        texIndexReal
    );

    if (PSCheckIsSelectedBlock(
        input.centerWorldPosition,
        uniforms
    ) > 0.5)
    {
        color.rgb = mix(
            color.rgb,
            uniforms.selectColor.rgb,
            uniforms.selectColor.a
        );
    }

    LightingParams lightingParams;
    lightingParams.normal = normalize(input.normal);
    lightingParams.sunDirection =
        normalize(uniforms.directionalLightDirection);
    lightingParams.sunColor = uniforms.directionalLightColor.rgb;
    lightingParams.ambientColor = uniforms.ambientLightColor.rgb;

    float3 lightColor = PSCalcLighting(lightingParams);

    color.rgb *= lightColor;
    output.color = color;

    return output;
}
