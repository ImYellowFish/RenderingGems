Shader "RGem/SSR"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MaxDistance ("Max trace distance", Float) = 1
		_IntersectDistMin("Min intersection distance", Float) = 0
		_IntersectThreshold ("Intersection Threshold", Range(0, 1)) = 0
		_DebugVar ("Debug Var", Float) = 0
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
			
			#include "UnityCG.cginc"
			#define TRACE_NUM 30

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
			sampler2D _CameraGBufferTexture2;
			sampler2D _CameraDepthTexture;
			float4x4 _ViewMatrix;
			float _MaxDistance;
			float _IntersectThreshold;
			float _DebugVar;
			float _IntersectDistMin;

			float GetDepth(float2 uv) {
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				return LinearEyeDepth(depth);
			}

			float GetViewDepthNormal(float2 uv, out float3 viewNormal) {
				fixed4 packedNormal = tex2D(_CameraGBufferTexture2, uv);
				float3 worldNormal = UnpackNormal(packedNormal);
				viewNormal = mul(_ViewMatrix, float4(worldNormal, 0.0)).xyz;
				return GetDepth(uv);
			}

			float3 ReconstructViewPos(float2 uv, float eyeDepth) {
				// view space position
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);
				return float3((uv * 2 - 1.0 - p13_31) / p11_22 * eyeDepth, -eyeDepth);
			}

			float GetViewDepthFromHPos(float4 projPos) {
				return unity_CameraProjection._34 / (projPos.z / projPos.w + unity_CameraProjection._33);
			}

			inline float CheckIntersect(float4 traceLineStart, float4 traceLineEnd, float4 sampleViewDepth) {
				float z0 = GetViewDepthFromHPos(traceLineStart);
				float z1 = GetViewDepthFromHPos(traceLineEnd);
				return z1 > sampleViewDepth;
			}

			float4 BruteRayTrace(float3 viewSpaceRayOrigin, float3 viewSpaceRayDir) {
				float3 viewSpaceRayEnd = viewSpaceRayOrigin + viewSpaceRayDir * _MaxDistance;
				float4 projSpaceRayOrigin = mul(unity_CameraProjection, float4(viewSpaceRayOrigin, 1.0));
				float4 projSpaceRayEnd = mul(unity_CameraProjection, float4(viewSpaceRayEnd, 1.0));
				projSpaceRayOrigin /= projSpaceRayOrigin.w;
				projSpaceRayEnd /= projSpaceRayEnd.w;
				
				float3 projSpaceRayDir = (projSpaceRayEnd - projSpaceRayOrigin).xyz;
				float rayLength = length(projSpaceRayDir);
				projSpaceRayDir /= rayLength;
				
				float traceDelta = rayLength / (TRACE_NUM + 1);

				float4 rayDelta = float4(projSpaceRayDir * traceDelta, 0);
				float4 traceLineStart = projSpaceRayOrigin + rayDelta * _IntersectDistMin;

				if(viewSpaceRayDir.z >= 0)
					return float4(1,0,0,1);

				//float3 tvend = viewSpaceRayOrigin + viewSpaceRayDir * _MaxDistance;
				//float4 tpend = mul(unity_CameraProjection, float4(tvend, 1));
				//float4 tpend = traceLineStart + rayDelta * TRACE_NUM;
				//float4 tpend2 = projSpaceRayOrigin + projSpaceRayDir * _MaxDistance;
				//return abs(tpend - tpend2);


				float4 traceLineEnd = traceLineStart + rayDelta;
				float trace = 0; // traceDistance
				for (int i = 0; i < TRACE_NUM; i++) {
					traceLineStart += rayDelta;
					traceLineEnd += rayDelta;

					trace += traceDelta;
					float4 projSpaceLineMid = traceLineStart + rayDelta / 2;
					float2 sampleUV = projSpaceLineMid.xy / projSpaceLineMid.w * 0.5 + 0.5;

					//if (i >= _DebugVar) {
					//	return tex2D(_MainTex, sampleUV);
					//}

					if (sampleUV.x > 1 || sampleUV.x < 0 || sampleUV.y > 1 || sampleUV.y < 0 || traceLineEnd.w < 0) {
						return float4(0, 0, 0, 1);
						// return float4(i * 1.0 / TRACE_NUM, 0, 0, 1);
					}
					float viewSpaceSampleDepth = GetDepth(sampleUV);
					//float3 viewSpaceSamplePos = ReconstructViewPos(sampleUV, viewSpaceSampleDepth);
					//float4 projSpaceSamplePos = mul(unity_CameraProjection, float4(viewSpaceSamplePos, 1.0));

					//if (i >= _DebugVar) {
					//	return viewSpaceSampleDepth / 100;
					//}
					//if (i >= _DebugVar) {
					//	return (viewSpaceSampleDepth - GetViewDepthFromHPos(traceLineStart)) * 100;
					//}
					
					float intersect = CheckIntersect(traceLineStart, traceLineEnd, viewSpaceSampleDepth);

					//if (i >= _DebugVar) {
					//	return intersect;
					//}

					if (intersect <= _IntersectThreshold) {
						return tex2D(_MainTex, sampleUV) * saturate(1.0 - intersect / (_IntersectThreshold + 0.01));
					}

				}
				return float4(0, 0, 1, 1);
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float3 viewNormal_o;
				float viewDepth_o = GetViewDepthNormal(i.uv, viewNormal_o);
				float3 viewPos_o = ReconstructViewPos(i.uv, viewDepth_o);
				float3 viewRay = normalize(viewPos_o);
				float3 reflectRay = normalize(reflect(viewRay, normalize(viewNormal_o)));
				float4 col = BruteRayTrace(viewPos_o, reflectRay);
				return col;
			}
			ENDCG
		}
	}
}
