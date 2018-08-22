//http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/

Shader "RGem/GaussianBlurBilinear"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_TexWidth ("Texture Width", Float) = 1024
		_TexHeight ("Texture Height", Float) = 768
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

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
			float4 uv_1 : TEXCOORD1;
			float4 uv_2 : TEXCOORD2;
			float4 vertex : SV_POSITION;
		};

		sampler2D _MainTex;
		float _TexWidth;
		float _TexHeight;

		// blur in the horizontal direction
		v2f vert_horizontal(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			float invTexWidth = 1.0 / _TexWidth;
			o.uv = v.uv;
			o.uv_1 = float4(1.3846 * invTexWidth + v.uv.x, v.uv.y, -1.3846 * invTexWidth + v.uv.x, v.uv.y);
			o.uv_2 = float4(3.2308 * invTexWidth + v.uv.x, v.uv.y, -3.2308 * invTexWidth + v.uv.x, v.uv.y);
			return o;
		}

		// blur in the vertical direction
		v2f vert_vertical(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			float invTexHeight = 1.0 / _TexHeight;
			o.uv = v.uv;
			o.uv_1 = float4(v.uv.x, 1.3846 * invTexHeight + v.uv.y, v.uv.x, -1.3846 * invTexHeight + v.uv.y);
			o.uv_2 = float4(v.uv.x, 3.2308 * invTexHeight + v.uv.y, v.uv.x, -3.2308 * invTexHeight + v.uv.y);
			return o;
		}
			
		// Sample 5 times for a 5 pixel kernel
		// Uses bilinear filtering to reduce sample amount.
		fixed4 frag (v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.uv);
			fixed4 col1 = tex2D(_MainTex, i.uv_1.xy);
			fixed4 col2 = tex2D(_MainTex, i.uv_1.zw);
			fixed4 col3 = tex2D(_MainTex, i.uv_2.xy);
			fixed4 col4 = tex2D(_MainTex, i.uv_2.zw);

			col = col * 0.2270 + col1 * 0.3162 + col2 * 0.3162 + col3 * 0.07027 + col4 * 0.07027;

			return col;
		}
		ENDCG

		Pass
		{
			Name "Gaussian_Linear_Kernel_5_Horizontal"
			CGPROGRAM
			#pragma vertex vert_horizontal
			#pragma fragment frag
			ENDCG
		}

		Pass
		{
			Name "Gaussian_Linear_Kernel_5_Vertical"
			CGPROGRAM
			#pragma vertex vert_vertical
			#pragma fragment frag
			ENDCG
		}
	}
}
