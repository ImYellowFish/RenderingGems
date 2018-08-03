Shader "RGem/Blur"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BlurSizeX ("Blur Size x", Float) = 0.1
		_BlurSizeY ("Blur Size y", Float) = 0.1
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
			float _BlurSizeX;
			float _BlurSizeY;

			fixed4 frag (v2f input) : SV_Target
			{
				fixed4 col;
				for (int i = 0; i < 3; i++) {
					for (int j = 0; j < 3; j++) {
						float2 blurUV = input.uv;
						blurUV.x += (i - 1.5) * _BlurSizeX;
						blurUV.y += (j - 1.5) * _BlurSizeY;
						float weight = 0.12 / ((i - 1.5) * (i - 1.5) + (j - 1.5) * (j - 1.5));
						col = tex2D(_MainTex, blurUV) * weight + col;
					}
				}
				//return tex2D(_MainTex, input.uv);
				return col;
			}
			ENDCG
		}
	}
}
