Shader "RGem/SSAOComposition"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_OcclusionTex("Occlusion", 2D) = "white" {}
		_OcclusionColor("Occlusion Color", Color) = (0,0,0,1)
		_Offset("Offset", Range(-1, 1)) = 0
		_Toggle("Toggle", Range(0, 1)) = 1
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
			sampler2D _OcclusionTex;
			fixed4 _OcclusionColor;
			float _Offset;
			float _Toggle;

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 occlusion = tex2D(_OcclusionTex, i.uv);
				col = col * min(occlusion.r + _Offset, 1.0);
				return col;
			}
			ENDCG
		}
	}
}
