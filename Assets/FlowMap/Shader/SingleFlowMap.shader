Shader "Unlit/SingleFlowMap"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_FlowMap("Flow Map", 2D) = "grey" {}
		
		_FlowSpeed("Flow Speed", Float) = 1
		_FlowMag("Flow Magnitude", Float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

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
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _FlowMap;
			float  _FlowSpeed;
			float _FlowMag;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 flowCol = tex2D(_FlowMap, i.uv);
				float2 uv_a = (flowCol.rg - 0.5) * (frac(_Time.y * _FlowSpeed) * _FlowMag) + i.uv;
				float2 uv_b = (flowCol.rg - 0.5) * (frac(_Time.y * _FlowSpeed + 0.5) * _FlowMag) + i.uv;
				float blend = abs(frac(_Time.y * _FlowSpeed) - 0.5) * 2;


				// sample the texture
				fixed4 col = lerp(tex2D(_MainTex, uv_a), tex2D(_MainTex, uv_b), blend);
				return col;
			}
			ENDCG
		}
	}
}
