Shader "Custom/HLSLMix" 
{
    Properties 
    {
        [Header(Shell)][Space]
        _ShellSize("Shell Size", range(0.01, 1.0)) = 1.0
        _ShellDirection("Shell Direction", vector) = (0, 0, 0, 0)
        _DisplacementStrength("Displacement Strenght", range(0.0, 0.99)) = 0.5
        //_Curvature("Curvature", float) = 1
        
        [Header(Colour and Noise)][Space]
        _BaseColor("Base color", Color) = (0, 0.5, 0, 1) // Color of the lowest layer
        _TopColor("Top color", Color) = (0, 1, 0, 1) // Color of the highest layer
        _DetailTextureA("Detail Texture A", 2D) = "white" {} // Texture A used to clip layers
        _TextureInfluenceA("Texture A Influence", Range(0, 1)) = 1 // The influence of Texture A
        _DetailTextureB("Detail Texture B", 2D) = "white" {} // Texture B used to clip layers
        _TextureInfluenceB("Texture B Influence", Range(0, 1)) = 1 // The influence of Texture B
        
        [Space(10)]
        
        [Header(Shading)][Space]
        [Toggle(DRAW_ORIG_POLYGON)]_DrawOrigPolygon("Draw Original Polygon", Float) = 1
        _DirectionThreshold("Direction Threshold", range(0.0, 1.0)) = 1.0


        [Space(50)]

        [Header(Basic)]
        //_AmbientColor("AmbientColor", Color) = (0.0, 0.0, 0.0, 1)
        _BaseMap("Base Map", 2D) = "white" {}
        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.5
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

        [Header(Fur)][Space]
        //[Toggle(DRAW_ORIG_POLYGON)]_DrawOrigPolygon("Draw Original Polygon", Float) = 1
        [NoScaleOffset] _FurMap("Fur Map", 2D) = "white" {}
        [NoScaleOffset] [Normal] _NormalMap("Normal", 2D) = "bump" {}
        _NormalScale("Normal Scale", Range(0.0, 2.0)) = 0.0
        _FaceNormalFactor("Face Normal Factor", Range(0.0, 0.5)) = 0.1
        [IntRange] _FinJointNum("Fin Joint Num", Range(1, 8)) = 3
        _AlphaCutout("Alpha Cutout", Range(0.0, 1.0)) = 0.2
        _FinLength("Length", Range(0.0, 1.0)) = 0.1
        _Density("Density", Range(0.1, 10.0)) = 1.0
        //_FaceViewProdThresh("Direction Threshold", Range(0.0, 1.0)) = 0.1
        _Occlusion("Occlusion", Range(0.0, 1.0)) = 0.3
        _RandomDirection("Random Direction", Range(0.0, 1.0)) = 0.3

        [Header(Move)][Space]
        _BaseMove("Base Move", Vector) = (0.0, -0.0, 0.0, 3.0)
        _WindFreq("Wind Freq", Vector) = (0.5, 0.7, 0.9, 1.0)
        _WindMove("Wind Move", Vector) = (0.2, 0.3, 0.2, 1.0)

        [Header(Tesselation)][Space]
        _TessMinDist("Tesselation Min Distance", Range(0.1, 50)) = 1.0
        _TessMaxDist("Tesselation Max Distance", Range(0.1, 50)) = 10.0
        _TessFactor("Tessellation Factor", Range(1, 10)) = 5

        [Header(Lighting)][Space]
        _RimLightPower("Rim Light Power", Range(1.0, 20.0)) = 6.0
        _RimLightIntensity("Rim Light Intensity", Range(0.0, 1.0)) = 0.5
        _ShadowExtraBias("Shadow Extra Bias", Range(-1.0, 1.0)) = 0.0
    }

    SubShader 
    {
        // UniversalPipeline needed to have this render in URP
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        //// Forward Lit Pass
        //Pass 
        //{

        //    Name "ForwardLit"
        //    Tags{"LightMode" = "UniversalForward"}
        //    Cull Back

        //    HLSLPROGRAM
        //    // Signal this shader requires geometry function support
        //    #pragma prefer_hlslcc gles
        //    #pragma exclude_renderers d3d11_9x
        //    #pragma target 2.0
        //    #pragma require geometry

        //    //// Lighting and shadow keywords
        //    //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        //    //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        //    //#pragma multi_compile _ _ADDITIONAL_LIGHTS
        //    //#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        //    //#pragma multi_compile _ _SHADOWS_SOFT

        //    // Register our functions
        //    #pragma vertex Vertex
        //    #pragma geometry Geometry
        //    #pragma fragment Fragment

        //    // Incude our logic file
        //    #include "Shell/Fur.hlsl"    

        //    ENDHLSL
        //}

        //Pass 
        //{

        //    Name "ShadowCaster"
        //    Tags {"LightMode" = "ShadowCaster"}

        //    HLSLPROGRAM
        //    // Signal this shader requires geometry function support
        //    #pragma prefer_hlslcc gles
        //    #pragma exclude_renderers d3d11_9x
        //    #pragma target 2.0
        //    #pragma require geometry

        //    // Support all the various light types and shadow paths
        //    //#pragma multi_compile_shadowcaster

        //    // Register our functions
        //    #pragma vertex Vertex
        //    #pragma geometry Geometry
        //    #pragma fragment Fragment

        //    // A custom keyword to modify logic during the shadow caster pass
        //    #define SHADOW_CASTER_PASS
        //    // Incude our logic file
        //    #include "Shell/Fur.hlsl"

        //    ENDHLSL
        //}

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite On
            Cull Back

            HLSLPROGRAM
            // URP
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            // Unity
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            #pragma exclude_renderers gles gles3 glcore
            #pragma multi_compile _ DRAW_ORIG_POLYGON
            #pragma vertex vert
            #pragma require tessellation tessHW
            #pragma hull hull
            #pragma domain domain
            #pragma require geometry
            #pragma geometry geom 
            #pragma fragment frag
            #include "Fin/Lit.hlsl"
            #include "Fin/LitTessellation.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma multi_compile_fog
            #pragma multi_compile _ DRAW_ORIG_POLYGON
            #pragma multi_compile _ APPEND_MORE_FINS
            #pragma vertex vert
            #pragma require tessellation tessHW
            #pragma hull hull
            #pragma domain domain
            #pragma require geometry
            #pragma geometry geom 
            #pragma fragment frag
            #include "Fin/Shadow.hlsl"
            #include "Fin/UnlitTessellation.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma multi_compile_fog
            #pragma multi_compile _ DRAW_ORIG_POLYGON
            #pragma multi_compile _ APPEND_MORE_FINS
            #pragma vertex vert
            #pragma require tessellation tessHW
            #pragma hull hull
            #pragma domain domain
            #pragma require geometry
            #pragma geometry geom 
            #pragma fragment frag
            #define SHADOW_CASTER_PASS
            #include "Fin/Shadow.hlsl"
            #include "Fin/UnlitTessellation.hlsl"
            ENDHLSL
        }
    }
}