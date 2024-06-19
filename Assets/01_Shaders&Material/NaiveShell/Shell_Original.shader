Shader "Custom/Fur_Original" {
	SubShader {
		Tags {
			"LightMode" = "ForwardBase"
		}

		Pass {
            Cull Off

			CGPROGRAM

			#pragma vertex vp
			#pragma fragment fp

			#include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

			struct VertexData {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

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


			float hash(uint n) {
				// Hash from Hugo Elias
				n = (n << 13U) ^ n;
				n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
				return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
			}


			v2f vp(VertexData v) {
				v2f i;

				float shellHeight = (float)_ShellIndex / (float)_ShellCount;

				shellHeight = pow(shellHeight, _ShellDistanceAttenuation);

				v.vertex.xyz += v.normal.xyz * _ShellLength * shellHeight;

                i.normal = normalize(UnityObjectToWorldNormal(v.normal));
				
				float k = pow(shellHeight, _Curvature);

				v.vertex.xyz += _ShellDirection * k * _DisplacementStrength;

                i.pos = UnityObjectToClipPos(v.vertex);

                i.uv = v.uv;

				return i;
			}

			float4 fp(v2f i) : SV_TARGET {
				float2 newUV = i.uv * _Density;

				float2 localUV = frac(newUV) * 2 - 1;
				
				float localDistanceFromCenter = length(localUV);

                uint2 tid = newUV;
				uint seed = tid.x + 100 * tid.y + 100 * 10;

                float shellIndex = _ShellIndex;
                float shellCount = _ShellCount;

                float rand = lerp(_NoiseMin, _NoiseMax, hash(seed));

                float h = shellIndex / shellCount;

				int outsideThickness = (localDistanceFromCenter) > (_Thickness * (rand - h));
				
				if (outsideThickness && _ShellIndex > 0) discard;
                
				float ndotl = DotClamped(i.normal, _WorldSpaceLightPos0) * 0.5f + 0.5f;

				ndotl = ndotl * ndotl;

				float ambientOcclusion = pow(h, _Attenuation);

				ambientOcclusion += _OcclusionBias;

				ambientOcclusion = saturate(ambientOcclusion);

                return float4(_ShellColor * ndotl * ambientOcclusion, 1.0);
			}
			ENDCG
		}
	}
}