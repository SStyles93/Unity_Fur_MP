// Include some helper functions
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
//Values used to change "transform" of the Shells
float _ShellSize;
float4 _ShellDirection;
float _DisplacementStrength;
float _Curvature;

//Color properties
float4 _BaseColor;
float4 _TopColor;
// These two textures are combined to create the fur pattern in the fragment function
TEXTURE2D(_DetailTextureA); SAMPLER(sampler_DetailTextureA); float4 _DetailTextureA_ST;
float _TextureInfluenceA;
TEXTURE2D(_DetailTextureB); SAMPLER(sampler_DetailTextureB); float4 _DetailTextureB_ST;
float _TextureInfluenceB;

half _metallic;
half3 _specular;
half _smoothness; 
half _occlusion;
half3 _emission; 
half _alpha;

uint _FurLayers;


// Vertex functions
VertexOutput Vertex(Attributes IN) 
{
    // Initialize the output struct
    VertexOutput output = (VertexOutput)0;

    // Calculate position and normal in world space
    VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
    output.positionWS = vertexInput.positionWS;
    output.normalWS = normalInput.normalWS;

    // Pass through the UV
    output.uv = IN.uv;
    return output;
}

// Geometry functions

// This function sets values in output after calculating position based on height
void SetupVertex(in VertexOutput input, inout GeometryOutput output, float height) 
{

    // Extrude the position from the normal based on the height
    float3 positionWS = input.positionWS + input.normalWS * (height * _ShellSize);
    
    //Move shell positions according to the _ShellDirection higher layers are more impacted by the height
    positionWS -= _ShellDirection * (height * _ShellSize * _DisplacementStrength);
    
    output.positionWS = positionWS;

    output.normalWS = input.normalWS;
    output.uv = float3(input.uv, height); // Store the layer height in uv.z
    output.positionCS = CalculatePositionCSWithShadowCasterLogic(positionWS, input.normalWS);
}

// 3 vertices per trianlge * max number of layers allowed by Unity
[maxvertexcount(3 * 24)]
void Geometry(triangle VertexOutput inputs[3], inout TriangleStream<GeometryOutput> outputStream) 
{
    // Initialize the output struct
    GeometryOutput output = (GeometryOutput)0;
    
    //For each layer
    for (int l = 0; l < _FurLayers; l++) {
        // The height percent
        float h = l / (float)(_FurLayers - 1);
        // For each point in the triangle
        for (int t = 0; t < 3; t++) {
            // Calculate the output data and add the vertex to the output stream
            SetupVertex(inputs[t], output, h);
            outputStream.Append(output);
        }
        // Each triangle is disconnected, so we need to call this to restart the triangle strip
        outputStream.RestartStrip();
    }
}

// Fragment functions

half4 Fragment(GeometryOutput input) : SV_Target 
{

    float2 uv = input.uv.xy;
    float height = input.uv.z;

    // Sample the two noise textures, applying their scale and offset
    float detailNoiseA = SAMPLE_TEXTURE2D(_DetailTextureA, sampler_DetailTextureA, TRANSFORM_TEX(uv, _DetailTextureA)).r;
    float detailNoiseB = SAMPLE_TEXTURE2D(_DetailTextureB, sampler_DetailTextureB, TRANSFORM_TEX(uv, _DetailTextureB)).r;
    // Combine the textures together using these scale variables. Lower values will reduce a texture's influence
    detailNoiseA = 1 - (1 - detailNoiseA) * _TextureInfluenceA;
    detailNoiseB = 1 - (1 - detailNoiseB) * _TextureInfluenceB;
    // If detailNoise * smoothNoise is less than height, this pixel will be discarded by the renderer
    clip(detailNoiseA * detailNoiseB - height);

    // If the code reaches this far, this pixel should render

#ifdef SHADOW_CASTER_PASS
    // If we're in the shadow caster pass, it's enough to return now. We don't care about color
    return 0;
#else
    // Gather some data for the lighting algorithm
    InputData lightingInput = (InputData)0;
    lightingInput.positionWS = input.positionWS;
    lightingInput.normalWS = NormalizeNormalPerPixel(input.normalWS); // Renormalize the normal to reduce interpolation errors
    lightingInput.viewDirectionWS = GetViewDirectionFromPosition(input.positionWS); // Calculate the view direction
    lightingInput.shadowCoord = CalculateShadowCoord(input.positionWS, input.positionCS); // Calculate the shadow map coord

    // Lerp between the two grass colors based on layer height
    float3 _diffuseColor = lerp(_BaseColor, _TopColor, height).rgb;   
    
    //InputData inputData, 
    //half3 albedo, 
    //half metallic, 
    //half3 specular,
    //half smoothness, 
    //half occlusion, 
    //half3 emission, 
    //half alpha
    //return UniversalFragmentPBR(lightingInput, _diffuseColor, _metallic, _specular, _smoothness, _occlusion, _emission, _alpha);
    return UniversalFragmentPBR(lightingInput, _diffuseColor, _metallic, _specular, _smoothness, _occlusion, _emission, 1);
     
#endif
}