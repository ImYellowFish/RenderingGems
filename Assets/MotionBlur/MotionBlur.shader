Shader "RGem/MotionBlur"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BlurAmount("Blur Amount", Range(0,1)) = 0.5
	}
	SubShader
	{
		CGINCLUDE
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

		v2f vert(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = v.uv;
			return o;
		}

		sampler2D _MainTex;
		float _BlurAmount;

		fixed4 fragBlendRGB(v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.uv);
			col.a = _BlurAmount;
			return col;
		}

		fixed4 fragOverwriteAlpha(v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.uv);
			return col;	// use ColorMask A
		}
		ENDCG
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragBlendRGB
			ENDCG
		}

		Pass
		{
			Blend One Zero
			ColorMask A
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragOverwriteAlpha
			ENDCG
		}
	}
}
