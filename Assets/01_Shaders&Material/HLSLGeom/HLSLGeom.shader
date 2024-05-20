Shader "Custom/HLSLGeom" {
    Properties {
        
        [Header(Shell Property)][Space]
        [IntRange] _FurLayers("NumberOfShells", Range(1, 256)) = 24
        _ShellSize("Shell Size", range(0.01, 1.0)) = 1.0
        _ShellDirection("Shell Direction", vector) = (0, 0, 0, 0)
        _DisplacementStrength("Displacement Strenght", range(0.0, 0.99)) = 0.5
        //_Curvature("Curvature", float) = 1
        
        [Header(Shell Color)][Space]
        _BaseColor("Base color", Color) = (0, 0.5, 0, 1) // Color of the lowest layer
        _TopColor("Top color", Color) = (0, 1, 0, 1) // Color of the highest layer
        _DetailTextureA("Detail Texture A", 2D) = "white" {} // Texture A used to clip layers
        _TextureInfluenceA("Texture A Influence", Range(0, 1)) = 1 // The influence of Texture A
        _DetailTextureB("Detail Texture B", 2D) = "white" {} // Texture B used to clip layers
        _TextureInfluenceB("Texture B Influence", Range(0, 1)) = 1 // The influence of Texture B

        [Header(Shell Basics)][Space]
        _occlusion("Occulsion", Range(0, 1)) = 0
        _smoothness("Roughness", Range(0, 1)) = 0
        _metallic("Metalness", Range(0, 1)) = 0
        _emission("Emissive", Color) = (0, 0, 0, 0)

        //_specular("Specular", vector) = (0, 0, 0, 0)
        //_alpha("alpha", float) = 0
        //_normalTS("normalTS", vector) = (0, 0, 0, 0)

        //_specular("specular", vector) = (0, 0, 0, 0)
        //_smoothness("smoothness", float) = 0
        //_emission("emission", Color) = (0, 0, 0, 0) 
        //_alpha("alpha", float) = 0
    }

    SubShader {
        // UniversalPipeline needed to have this render in URP
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
            #include "Fur.hlsl"    

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
            // Incude our logic file
            #include "Fur.hlsl"

            ENDHLSL
        }
    }
}