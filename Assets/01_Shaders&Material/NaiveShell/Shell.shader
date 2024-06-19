Shader "Custom/Fur" {
	SubShader {
		Tags {
			"RenderType" = "Transparent"
			"RenderPipeline" = "UniversalPipeline"
			"UniversalMaterialType" = "Lit"
			"LightMode" = "UniversalForward"
			"Queue" = "Transparent"
		}

		Pass 
		{
			//Shader parameters
			LOD 100
			Cull Back
				
			
			Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}


			//Beginning of the program
			HLSLPROGRAM

			//Declaraction of Vertex and Fragment Shader
			#pragma vertex vert
			#pragma fragment frag

			//Inclusion of Unity Libraries
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
	
			//Attribute struct
			struct Attributes 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
			};

			//Varyings is the strucs that replaces v2f (Vertex to Frament)
			struct Varyings 
			{
				float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};


			CBUFFER_START(UnityPerMaterial)
            int _ShellIndex; 
			int _ShellCount; 
			float _ShellLength;
			float _Density; 
			float _NoiseMin, _NoiseMax;
			float _Thickness; 
			float _Attenuation;
			float _OcclusionBias;
			float _ShellDistanceAttenuation;
			float _Curvature;
			float _DisplacementStrength;
			float3 _ShellColor;
			float3 _ShellDirection;
			CBUFFER_END

			float hash(uint n) 
			{
				// integer hash copied from Hugo Elias
				n = (n << 13U) ^ n;
				n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
				return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
			}


			//The Vertex shader
			Varyings vert(Attributes IN) 
			{
				Varyings OUT;

				float shellHeight = (float)_ShellIndex / (float)_ShellCount;
				
				shellHeight = abs(pow(shellHeight, _ShellDistanceAttenuation));

				IN.vertex.xyz += IN.normal.xyz * _ShellLength * shellHeight;

                OUT.normal = normalize(TransformObjectToWorldNormal(IN.normal));
				
				float k = pow(shellHeight, _Curvature);

				IN.vertex.xyz += _ShellDirection * k * _DisplacementStrength;

				OUT.pos = TransformObjectToHClip(IN.vertex);
                OUT.uv = IN.uv;

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target 
			{
				float2 newUV = IN.uv * _Density;
				float2 localUV = frac(newUV) * 2 - 1;
				float localDistanceFromCenter = length(localUV);
                
				uint2 tid = newUV;
				uint seed = tid.x + 100 * tid.y + 100 * 10;

				// instead of (float)_ShellIndex && (float)_ShellCount
                float shellIndex = _ShellIndex;
                float shellCount = _ShellCount;

				//Lerp between min and max noise according to random generator function
                float rand = lerp(_NoiseMin, _NoiseMax, hash(seed));

				// This is the normalized shell height as in the vertex shader
                float h = shellIndex / shellCount;

				int outsideThickness = (localDistanceFromCenter) > (_Thickness * (rand - h));
				
				if (outsideThickness && _ShellIndex > 0)
				{
					discard;
				}
				
				float ndotl = clamp(dot(IN.normal, _MainLightPosition),0,1) * 0.5f + 0.5f;

				ndotl = ndotl * ndotl;

				float ambientOcclusion = pow(h, _Attenuation);
				ambientOcclusion += _OcclusionBias;
				ambientOcclusion = saturate(ambientOcclusion);
                
				return float4(_ShellColor * ndotl * ambientOcclusion, 1.0);

			}
			ENDHLSL
		}
	}
}