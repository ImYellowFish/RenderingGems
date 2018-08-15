Shader "RGem/SSAO"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_KernelRadius ("Kernel Radius", Float) = 1
		_DepthCheckOffset ("Depth Check Offset", Float) = 1
		_OcclusionOffset("Occlusion Offset", Range(-0.5, 0.5)) = 0
		_AOStrength("AO strength", Float) = 1
		_Contrast("Contrast", Float) = 1
		[Toggle]_GBuffer("Use GBuffer", Int) = 0
		[Toggle]_Morgan("Use Mogan Estimator", Int) = 0
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma shader_feature _GBUFFER_ON
			#pragma shader_feature _MORGAN_ON
			#pragma vertex vert
			#pragma fragment frag
			#define KERNEL_SIZE 16

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			sampler2D _CameraDepthNormalsTexture;
			sampler2D _CameraGBufferTexture2;
			float _KernelRadius;
			float _DepthCheckOffset;
			float _OcclusionOffset;
			float _AOStrength;
			float _Contrast;

			float4 _Kernel[KERNEL_SIZE];

			// Boundary check for depth sampler
			// (returns a very large value if it lies out of bounds)
			float CheckBounds(float2 uv, float d)
			{
				float ob = any(uv < 0) + any(uv > 1);
				#if defined(UNITY_REVERSED_Z)
					ob += (d <= 0.00001);
				#else
					ob += (d >= 0.99999);
				#endif
				return ob * 1e8;
			}

			float GetViewDepthNormal(float2 uv, out float3 viewNormal) {
				#if defined(_GBUFFER_ON)
					float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
					fixed4 packedNormal = tex2D(_CameraGBufferTexture2, uv);
					float3 worldNormal = UnpackNormal(packedNormal);
					viewNormal = mul(UNITY_MATRIX_V, float4(worldNormal, 1.0)).xyz;
					return LinearEyeDepth(depth) + CheckBounds(uv, depth);
				#else
					float depth;
					DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv), depth, viewNormal);
					return depth * _ProjectionParams.z + CheckBounds(uv, depth);
				#endif
			}

			float4 ReconstructViewPos(float2 uv, float eyeDepth) {
				// view space position
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);
				return float4((uv * 2 - 1.0 - p13_31) / p11_22 * eyeDepth, -eyeDepth, 1);
			}


			fixed4 frag (v2f i) : SV_Target
			{
				float3 viewNormal;
				float depth;
				float eyeDepth;
				
				eyeDepth = GetViewDepthNormal(i.uv, viewNormal);

				// peek depth normal
				//return float4(depth, depth, depth, 1);

				//// peek depth texture
				// float d2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				// return float4(d2, d2, d2, 1) * _AOStrength;

				float4 hpos;
				hpos.xy = i.uv * 2 - 1;
				hpos.z = -eyeDepth;
				hpos.w = 1;

				// view space position
				float4 origin = ReconstructViewPos(i.uv, eyeDepth);
				
				// calculate view to tangent space transform
				float3 noiseDir = float3(frac(i.uv.x * 12111 + i.uv.y * 111279 + frac(_Time.y) * 14117) * 2 - 1, 
					frac(i.uv.x * 11223 *1 - i.uv.y * 12533 - frac(_Time.y) * 15129 + 0.124312) * 2 - 1, 0);
				float3 viewTangent = normalize(noiseDir - viewNormal * dot(noiseDir, viewNormal));
				float3 viewBinormal = cross(viewNormal, viewTangent);
				
				//return float4(viewBinormal, 1);

				
				float occlusion = 0.0;

				for (int index = 0; index < KERNEL_SIZE; index++) {
					/*float3 kernelSample = float3(frac(noiseDir.x * 345 * index * index) * 2 - 1,
						frac(noiseDir.y * 234 * index * index) * 2 - 1, 
						frac(noiseDir.z * 123 * index * index));
					normalize(kernelSample);*/
					float3 kernelSample = _Kernel[index].xyz;
					float3 sampleOffset = viewTangent * kernelSample.x +
						viewBinormal * kernelSample.y + viewNormal * kernelSample.z;
					float3 samplePos = origin + sampleOffset * _KernelRadius;
					//samplePos = origin + kernelSample * _KernelRadius;

					// project sample position
					float4 projSamplePos = mul(unity_CameraProjection, float4(samplePos, 1.0));
					float2 sampleUV = projSamplePos.xy / projSamplePos.w * 0.5 + 0.5;
					//sampleUV.xy = 1 - sampleUV.xy;
					
					float occlusionDepth;
					float3 sampleNormal;

					occlusionDepth = GetViewDepthNormal(sampleUV, sampleNormal);

					//float td = occlusionDepth / 15;
					//return float4(td, td, td, 1);

					// float td = samplePos.z * 80;
					// return float4(td, td, td, 1);

					#if defined(_MORGAN_ON)
						float4 occluSamplePos = ReconstructViewPos(sampleUV, occlusionDepth);
						float3 deltaPos = occluSamplePos.xyz - origin.xyz;
						float a1 = max(dot(deltaPos, viewNormal) - 0.002 * eyeDepth - _OcclusionOffset, 0);
						float a2 = dot(deltaPos, deltaPos) + 1e-4;
						occlusion += a1 / a2;
					#else
						float depthRangeCheck = abs(occlusionDepth - eyeDepth) < _DepthCheckOffset ? 1.0 : 0.0;
						occlusion += (occlusionDepth + _OcclusionOffset <= (-samplePos.z) ? 1.0 : 0.0) * depthRangeCheck;
					#endif
					/*fixed4 col_debug = 1;
					col_debug.rgb = sampleOffset;
					return col_debug;*/

				}
				#if defined(_MORGAN_ON)
					fixed4 col = 1 - pow(occlusion / KERNEL_SIZE * _AOStrength, _Contrast);
				#else
					fixed4 col = 1 - occlusion / KERNEL_SIZE * _AOStrength;
				#endif
				//col.rgb = _Kernel[15];
				return col;
			}
			ENDCG
		}
	}
}
