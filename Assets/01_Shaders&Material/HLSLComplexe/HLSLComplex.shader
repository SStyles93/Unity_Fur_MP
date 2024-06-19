Shader "Custom/HLSLComplex" {
    Properties {
        
        [Header(Shell Property)][Space]
        [IntRange] _FurLayers("NumberOfShells", Range(2, 24)) = 24
        _ShellSize("Shell Size", range(0.01, 1.0)) = 1.0
        _ShellDirection("Shell Direction", vector) = (0, 0, 0, 0)
        _DisplacementStrength("Displacement Strenght", range(0.0, 0.99)) = 0.5
        
        
        [Space(20)][Header(Shell Parameters)][Space]
        _DetailTextureA("Detail Texture A", 2D) = "white" {} // Texture A used to clip layers
        _TextureInfluenceA("Texture A Influence", Range(0, 1)) = 1 // The influence of Texture A
        _DetailTextureB("Detail Texture B", 2D) = "white" {} // Texture B used to clip layers
        _TextureInfluenceB("Texture B Influence", Range(0, 1)) = 1 // The influence of Texture B

        [Space(20)][Header(Object Material)][Space(10)]
        [MainTexture] _BaseColor("Base Color", 2D) = "white" {}
        _TintColor("Tint Color", Color) = (0, 0.5, 0, 1)
        _TopColor("Top Color", Color) = (0, 1, 0, 1)
        _Occlusion("Occulsion", 2D) = "white" {}
        _OcclusionValue("Occulsion Value", Range(0, 1)) = 0
        _Smoothness("Roughness",  2D) = "white" {}
        _SmoothnessValue("Roughness Value", Range(0, 1)) = 0
        _Metalness("Metalness", 2D) = "white" {}
        _MetalnessValue("Metalness Value", Range(0, 1)) = 0
        _Emissive("Emissive", 2D) = "white" {}
        _EmissionTint("Emission Tint", Color) = (0, 0, 0, 0)
        
    }

    SubShader {

        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        // Forward Lit Pass
        Pass {

            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            Cull Back

            HLSLPROGRAM
            // Signal this shader requires geometry function support
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma require geometry

            // Lighting and shadow keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            // Register our functions
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment
			
            // Incude our logic file
            #include "FurComplex.hlsl"    

            ENDHLSL
        }

        Pass {

            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}

            HLSLPROGRAM
            // Signal this shader requires geometry function support
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma require geometry

            // Support all the various light types and shadow paths
            #pragma multi_compile_shadowcaster

            // Register our functions
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment

            // A custom keyword to modify logic during the shadow caster pass
            #define SHADOW_CASTER_PASS

            #include "FurComplex.hlsl"

            ENDHLSL
        }
    }
}