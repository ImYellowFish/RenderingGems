Shader "RGem/SunShaft/SunShaft"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_SampleCount("_SampleCount", Int) = 5
		_LightTex("_SunShaftLightTex", 2D) = "black"{}
		_Decay("_Decay", Range(0.8,1)) = 0.9
		_Exposure("_Exposure", Range(0,2)) = 1
		_NoiseIntensity("_NoiseIntensity", Float) = 0.1
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
			sampler2D _SunShaftLightTex;
			float4 _SunScreenPos;
			float _SampleCount;
			float _NoiseIntensity;
			float _Decay;
			float _Exposure;

			fixed4 frag (v2f i) : SV_Target
			{
				float2 selfToSunDir = (_SunScreenPos.xy - i.uv) / _SampleCount;
				float lerpFactor = 0.1;
				float lerpStep = 0.8 / _SampleCount;
				float2 currentUV = i.uv;
				fixed4 col = tex2D(_MainTex, currentUV);
				float decay = 1.0;
				[unroll(100)] for (int j = 1; j < _SampleCount; j++) {
					currentUV += selfToSunDir;
					decay *= _Decay;
					float noise = frac(100231 * sin(i.uv.x * 31 + i.uv.y * 211 + _Time.x * 0.01) + 0.2) * _NoiseIntensity;
					fixed4 tmp = tex2D(_SunShaftLightTex, lerp(i.uv, currentUV, lerpFactor + noise));
					col = col + tmp * decay * _Exposure;
					lerpFactor += lerpStep;
				}
				return col;
			}
			ENDCG
		}
	}
}
