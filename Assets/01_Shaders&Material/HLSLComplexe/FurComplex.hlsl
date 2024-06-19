#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Common.hlsl"

struct Attributes {
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 uv           : TEXCOORD0;
};

struct VertexOutput {
    float3 positionWS   : TEXCOORD0;
    float3 normalWS     : TEXCOORD1;
    float2 uv           : TEXCOORD2;
};

struct GeometryOutput {
    float3 uv           : TEXCOORD0;
    float3 positionWS   : TEXCOORD1;
    float3 normalWS     : TEXCOORD2;
    float4 positionCS   : SV_POSITION;
};

// Properties
float _ShellSize;
float4 _ShellDirection;
float _DisplacementStrength;
float _Curvature;

//Color properties
TEXTURE2D(_BaseColor); SAMPLER(sampler_BaseColor); float4 _BaseColor_ST;
float4 _TintColor;
float4 _TopColor;
half3 _Specular;
TEXTURE2D(_Occlusion); SAMPLER(sampler_Occlusion); float4 _Occlusion_ST;
half _OcclusionValue; 
TEXTURE2D(_Smoothness); SAMPLER(sampler_Smoothness); float4 _Smoothness_ST;
half _SmoothnessValue; 
TEXTURE2D(_Metalness); SAMPLER(sampler_Metalness); float4 _Metalness_ST;
half _MetalnessValue;
TEXTURE2D(_Emissive); SAMPLER(sampler_Emissive); float4 _Emissive_ST;
half3 _EmissionTint; 

// Textures for the fur pattern
TEXTURE2D(_DetailTextureA); SAMPLER(sampler_DetailTextureA); float4 _DetailTextureA_ST;
float _TextureInfluenceA;
TEXTURE2D(_DetailTextureB); SAMPLER(sampler_DetailTextureB); float4 _DetailTextureB_ST;
float _TextureInfluenceB;

uint _FurLayers;


VertexOutput Vertex(Attributes IN) {
    
    VertexOutput output = (VertexOutput)0;

    VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
    output.positionWS = vertexInput.positionWS;
    output.normalWS = normalInput.normalWS;

    output.uv = IN.uv;
    return output;
}

void SetupVertex(in VertexOutput input, inout GeometryOutput output, float height) {

    float3 positionWS = input.positionWS + input.normalWS * (height * _ShellSize);
    
    positionWS -= _ShellDirection * (height * _ShellSize * _DisplacementStrength);
    
    output.positionWS = positionWS;

    output.normalWS = input.normalWS;
    output.uv = float3(input.uv, height);
    output.positionCS = CalculatePositionCSWithShadowCasterLogic(positionWS, input.normalWS);
}

[maxvertexcount(3 * 24)]
void Geometry(triangle VertexOutput inputs[3], inout TriangleStream<GeometryOutput> outputStream) {
    
    GeometryOutput output = (GeometryOutput)0;
    
    for (int l = 0; l < _FurLayers; l++) {
        float h = l / (float)(_FurLayers - 1);
        for (int t = 0; t < 3; t++) 
        {
            SetupVertex(inputs[t], output, h);
            outputStream.Append(output);
        }
        
        outputStream.RestartStrip();
    }
}

half4 Fragment(GeometryOutput input) : SV_Target {

    float2 uv = input.uv.xy;
    float height = input.uv.z;

    float detailNoiseA = SAMPLE_TEXTURE2D(_DetailTextureA, sampler_DetailTextureA, TRANSFORM_TEX(uv, _DetailTextureA)).r;
    float detailNoiseB = SAMPLE_TEXTURE2D(_DetailTextureB, sampler_DetailTextureB, TRANSFORM_TEX(uv, _DetailTextureB)).r;

    detailNoiseA = 1 - (1 - detailNoiseA) * _TextureInfluenceA;
    detailNoiseB = 1 - (1 - detailNoiseB) * _TextureInfluenceB;

    clip(detailNoiseA * detailNoiseB - height);

#ifdef SHADOW_CASTER_PASS
    return 0;
#else

    InputData lightingInput = (InputData)0;
    lightingInput.positionWS = input.positionWS;
    lightingInput.normalWS = NormalizeNormalPerPixel(input.normalWS);
    lightingInput.viewDirectionWS = GetViewDirectionFromPosition(input.positionWS);
    lightingInput.shadowCoord = CalculateShadowCoord(input.positionWS, input.positionCS);

    float3 _diffuseColor = lerp(
        SAMPLE_TEXTURE2D(_BaseColor, sampler_BaseColor, TRANSFORM_TEX(uv, _BaseColor)) * _TintColor, 
        SAMPLE_TEXTURE2D(_BaseColor, sampler_BaseColor, TRANSFORM_TEX(uv, _BaseColor)) *_TopColor,
        height).rgb;
    half _occlusion = SAMPLE_TEXTURE2D(_Occlusion, sampler_Occlusion, TRANSFORM_TEX(uv, _Occlusion)) * _OcclusionValue;
    half _smoothness = SAMPLE_TEXTURE2D(_Smoothness, sampler_Smoothness, TRANSFORM_TEX(uv, _Smoothness)) * _SmoothnessValue;
    half _metallic = SAMPLE_TEXTURE2D(_Metalness, sampler_Metalness, TRANSFORM_TEX(uv, _Metalness)) * _MetalnessValue;
    half3 _emissive = SAMPLE_TEXTURE2D(_Emissive, sampler_Emissive, TRANSFORM_TEX(uv, _Emissive)) * _EmissionTint;
    
    //InputData inputData, 
    //half3 albedo, 
    //half metallic, 
    //half3 specular,
    //half smoothness, 
    //half occlusion, 
    //half3 emission, 
    //half alpha
    //return UniversalFragmentPBR(lightingInput, _diffuseColor, _metallic, _specular, _smoothness, _occlusion, _emission, _alpha);
    return UniversalFragmentPBR(lightingInput, _diffuseColor, _metallic, _Specular, _smoothness, _occlusion, _emissive, 1);
    
#endif
}