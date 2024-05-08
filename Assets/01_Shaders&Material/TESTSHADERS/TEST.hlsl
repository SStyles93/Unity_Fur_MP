#ifndef FUR_LAYERS
#define FUR_LAYERS

// Include some helper functions
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "CommonTEST.hlsl"

// Change this to change the number of layers created by the geometry function
#define FUR_LAYERS 24

// The vertex function input
struct Attributes {
    float4 positionOS   : POSITION; // Vertex position in object space
    float3 normalOS     : NORMAL; // Vertex normal vector in object space
    float4 tangentOS    : TANGENT; // Vertex tangent vector in object space
    float2 uv           : TEXCOORD0; // Vertex uv
};

// Vertex function output and geometry function input
struct VertexOutput {
    float3 positionWS   : TEXCOORD0; // Position in world space
    float3 normalWS     : TEXCOORD1; // Normal vector in world space
    float2 uv           : TEXCOORD2; // UV, no scaling applied
};

// Geometry function output and fragment function input
struct GeometryOutput {
    float3 uv           : TEXCOORD0; // UV, no scaling applied, plus the layer height in the z-coord
    float3 positionWS   : TEXCOORD1; // Position in world space
    float3 normalWS     : TEXCOORD2; // Normal vector in world space
    float4 positionCS   : SV_POSITION; // Position in clip space
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

float _DirectionThreshold;

// Vertex functions
VertexOutput Vertex(Attributes IN) {
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
void SetupVertex(in VertexOutput input, inout GeometryOutput output, float height) {

    // Extrude the position outwards along the normal based on the passed in height
    float3 positionWS = input.positionWS + input.normalWS * (height * _ShellSize);
    
    //Move shell positions according to the _ShellDirection higher layers are more impacted by the height
    positionWS -= _ShellDirection * (height * _ShellSize * _DisplacementStrength);
    
    output.positionWS = positionWS;

    output.normalWS = input.normalWS;
    output.uv = float3(input.uv, height); // Store the layer height in uv.z
    output.positionCS = CalculatePositionCSWithShadowCasterLogic(positionWS, input.normalWS);
}

// We create FUR_LAYERS triangles which have 3 vertices each
[maxvertexcount(3 * FUR_LAYERS)]
void Geometry(triangle VertexOutput inputs[3], inout TriangleStream<GeometryOutput> outputStream) {
    // Initialize the output struct
    GeometryOutput output = (GeometryOutput)0;
    
    //For each layer
    for (int l = 0; l < FUR_LAYERS; l++) {
        // The height percent
        float h = l / (float)(FUR_LAYERS - 1);
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

half4 Fragment(GeometryOutput input) : SV_Target {

    float2 uv = input.uv.xy;
    // Height percent is uv.z
    float height = input.uv.z;

    // Sample the two noise textures, applying their scale and offset
    float detailNoiseA = SAMPLE_TEXTURE2D(_DetailTextureA, sampler_DetailTextureA, TRANSFORM_TEX(uv, _DetailTextureA)).r;
    float detailNoiseB = SAMPLE_TEXTURE2D(_DetailTextureB, sampler_DetailTextureB, TRANSFORM_TEX(uv, _DetailTextureB)).r;
    // Combine the textures together using these scale variables. Lower values will reduce a texture's influence
    detailNoiseA = 1 - (1 - detailNoiseA) * _TextureInfluenceA;
    detailNoiseB = 1 - (1 - detailNoiseB) * _TextureInfluenceB;

    //Discards the pixels that have a normal pointing out further than a certain value 
    if(dot(GetViewDirectionFromPosition(input.positionWS), input.normalWS) < _DirectionThreshold) {
        if(height > 0.01)
        discard;
    }


    // If detailNoise * smoothNoise is less than height, this pixel will be discarded by the renderer
    // I.E. this pixel will not render. The fragment function returns as well
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
    float3 albedo = lerp(_BaseColor, _TopColor, height).rgb;

    // The URP simple lit algorithm 
    //inputData, diffuse, specularGloss, smoothness, emission, alpha, normalTS)
    return UniversalFragmentBlinnPhong(lightingInput, albedo, 1, 0, 0, 1, 1);
#endif
}

#endif