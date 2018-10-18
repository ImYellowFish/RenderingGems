Shader "RGem/ShadowReceiver"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
				float4 shadowSpacePos: TEXCOORD2;
			};

			sampler2D _MainTex;
			sampler2D _MyShadowTex;
			float4 _MainTex_ST;

			float4x4 _MyShadowMatrixVP;

			v2f vert (appdata v)
			{
				v2f o;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.vertex = mul(UNITY_MATRIX_VP, worldPos);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o.shadowSpacePos = mul(_MyShadowMatrixVP, worldPos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				float2 shadowUV = (i.shadowSpacePos.xy / i.shadowSpacePos.w) * 0.5 + 0.5;
				float objDepth = i.shadowSpacePos.z / i.shadowSpacePos.w;
				float shadowMapDepth = DecodeFloatRGBA(tex2D(_MyShadowTex, shadowUV));
				float inShadow = step(shadowMapDepth, objDepth);
				return col * (1.0 - inShadow);
			}
			ENDCG
		}
	}
}
