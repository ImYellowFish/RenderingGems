Shader "RGem/TestDepthNormal"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ShowDepth ("ShowDepth", Range(0,1)) = 0
		_DepthScale ("DepthScale", Float) = 80
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
			sampler2D _CameraDepthNormalsTexture;
			float _ShowDepth;
			float _DepthScale;

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col;
				float4 enc = tex2D(_CameraDepthNormalsTexture, i.uv);
				float depth;
				float3 normal;
				DecodeDepthNormal(enc, depth, normal);
				if (_ShowDepth <= 0.5) {
					col.rgb = normal * 0.5 + 0.5;
				}
				else {
					col.rgb = depth * _DepthScale;
				}
				col.a = 1;
				return col;
			}
			ENDCG
		}
	}
}
