Shader "RGem/FlowMapFur"
{
	Properties
	{
		_MainTex ("Main Tex", 2D) = "white" {}
		_FurTex("Fur Tex", 2D) = "white" {}
		_FlowMap("Flow Map", 2D) = "grey" {}
		_FlowSpeed("Flow Speed", Float) = 1
		_FlowMag("Flow Magnitude", Float) = 1
		_Blur("Blur Intensity", Float) = 0.5
		_NoiseSpeed("Noise Speed", Float) = 1.0
		_FurColor("Fur Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent"}
		LOD 100
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _FurTex;
			float4 _FurTex_ST;
			float4 _FurTex_TexelSize;

			half4 _FurColor;

			sampler2D _FlowMap;
			float  _FlowSpeed;
			float _FlowMag;
			float _Blur;
			float _NoiseSpeed;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv, _FurTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half4 mainCol = tex2D(_MainTex, i.uv.xy);
				half4 flowCol = tex2D(_FlowMap, i.uv.xy);
				float2 duv = min((flowCol.rg - 0.5) * _FlowMag * _FurTex_TexelSize.xy, 0.01);
				float2 current_uv = i.uv.zw;
				half4 furCol = half4(0, 0, 0, 0);
				half weight = 0.0;
				half d_weight;
				for (int ci = 1; ci <= 8; ci++) {
					d_weight = 1.0 / sqrt(ci);
					half2 uv_noise = _FurTex_TexelSize.xy * _FlowMag * (0.04 * ci * cos(_Time.x * 50 * _NoiseSpeed + i.uv.xy * 20));
					weight += d_weight;
					furCol.rgba += lerp(1.0, _FurColor.rgba, tex2D(_FurTex, current_uv + uv_noise).r * mainCol.a) * d_weight;
					current_uv += duv;
				}
				furCol = furCol / weight;
				// multiply the color
				fixed4 col = mainCol * furCol;
				col.a = 1.0;
				return col;
			}
			ENDCG
		}
	}
}
