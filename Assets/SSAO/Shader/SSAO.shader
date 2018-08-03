Shader "RGem/SSAO"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_KernelRadius ("Kernel Radius", Float) = 1
		_DepthCheckOffset ("Depth Check Offset", Float) = 1
		_OcclusionOffset("Occlusion Offset", Range(-0.5, 0.5)) = 0
		_AOStrength("AO strength", Float) = 1
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
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
			float _KernelRadius;
			float _DepthCheckOffset;
			float _OcclusionOffset;
			float _AOStrength;

			float4 _Kernel[KERNEL_SIZE];

			fixed4 frag (v2f i) : SV_Target
			{
				float3 viewNormal;
				float depth;
				
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.uv), depth, viewNormal);
				// peek depth normal
				//return float4(depth, depth, depth, 1);
				
				// peek depth texture
				// float d2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				// return float4(d2, d2, d2, 1) * _AOStrength;

				float eyeDepth = depth * _ProjectionParams.z;
				
				float4 hpos;
				hpos.xy = i.uv * 2 - 1;
				hpos.z = -eyeDepth;
				hpos.w = 1;

				// view space position
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);
				// float4 origin = float4((hpos.xy - p13_31) / p11_22 * depth, depth, 1);
				float4 origin = float4((hpos.xy - p13_31) / p11_22 * eyeDepth, -eyeDepth, 1);
				
				// calculate view to tangent space transform
				float3 noiseDir = float3(frac(i.uv.x * 3711 + i.uv.y * 1179) * 2 - 1, 
					frac(i.uv.x * 4123 *1 + i.uv.y * 4233 + 0.124312) * 2 - 1, 0);
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
					DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, sampleUV),
						occlusionDepth, sampleNormal);

					occlusionDepth = occlusionDepth * _ProjectionParams.z;
					float td = occlusionDepth / 15;
					//return float4(td, td, td, 1);

					// float td = samplePos.z * 80;
					// return float4(td, td, td, 1);

					
					float depthRangeCheck = abs(occlusionDepth - eyeDepth) < _DepthCheckOffset ? 1.0 : 0.0;
					occlusion += (occlusionDepth + _OcclusionOffset <= (-samplePos.z) ? 1.0 : 0.0) * depthRangeCheck;

					/*fixed4 col_debug = 1;
					col_debug.rgb = sampleOffset;
					return col_debug;*/

				}

				fixed4 col = 1 - occlusion / KERNEL_SIZE * _AOStrength;
				//col.rgb = _Kernel[15];
				return col;
			}
			ENDCG
		}
	}
}
