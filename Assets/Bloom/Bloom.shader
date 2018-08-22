Shader "RGem/Bloom"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Threshold ("Threshold", Float) = 1
		_BlurPixelOffset ("BlurPixelOffset", Float) = 1
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

		sampler2D _MainTex;
		sampler2D _BloomTex;
		float2 _MainTex_TexelSize;
		float _Threshold;
		float _BlurPixelOffset;

		v2f vert(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = v.uv;
			return o;
		}

		fixed4 BlurFourTap(float2 uv) {
			float4 tap_offsets = _BlurPixelOffset * 
				float4(1.0, 1.0, 1.0, -1.0) * _MainTex_TexelSize.xyxy;
			fixed4 col0 = tex2D(_MainTex, uv + tap_offsets.xy);
			fixed4 col1 = tex2D(_MainTex, uv - tap_offsets.xy);
			fixed4 col2 = tex2D(_MainTex, uv + tap_offsets.zw);
			fixed4 col3 = tex2D(_MainTex, uv - tap_offsets.zw);
			return (col0 + col1 + col2 + col3) * 0.25;
		}

		fixed4 fragPrefilter(v2f i) : SV_Target
		{
			// TODO: do one blur in this stage
			fixed4 col = tex2D(_MainTex, i.uv);
			col.rgb = saturate(col.rgb - _Threshold);
			return col;
		}

		fixed4 fragBlurFourTap(v2f i) : SV_Target
		{
			fixed4 col = BlurFourTap(i.uv);
			return col;
		}

		fixed4 fragCombine(v2f i) : SV_Target
		{
			// upsampling
			fixed4 bloom = BlurFourTap(i.uv);

			// combined color
			fixed4 col = tex2D(_BloomTex, i.uv);
			
			// combine
			col.rgb += bloom.rgb;
			return col;
		}
		ENDCG


		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			Name "BloomPrefilter"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragPrefilter
			ENDCG
		}

		Pass
		{
			Name "BloomDownsampling"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragBlurFourTap
			ENDCG
		}

		Pass
		{
			Name "BloomCombine"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragCombine
			ENDCG
		}
	}
}
