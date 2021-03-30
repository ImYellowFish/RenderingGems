Shader "RGem/StencilOutlinePostprocess"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_OutlineTex("_OutlineTex", 2D) = "clear" {}
		_OutlineStrength("_OutlineStrength", Range(0.1, 3)) = 1.0
		_BlurPixelStep("_BlurPixel", Range(0.1, 3)) = 1.0
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			// Blur
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

			float _BlurPixelStep;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;

			fixed4 frag (v2f i) : SV_Target
			{
				float2 step = _ScreenParams.zw * _BlurPixelStep - _BlurPixelStep;
				fixed4 col = tex2D(_MainTex, i.uv + float2(step.x, step.y)) * 0.25
					+ tex2D(_MainTex, i.uv + float2(step.x, -step.y)) * 0.25
					+ tex2D(_MainTex, i.uv + float2(-step.x, step.y)) * 0.25
					+ tex2D(_MainTex, i.uv + float2(-step.x, -step.y)) * 0.25;
				return col;
			}
			ENDCG
		}

		Pass
		{
			// Blend
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

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			sampler2D _MainTex;
			sampler2D _OutlineTex;
			fixed _OutlineStrength;

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 outline = tex2D(_OutlineTex, i.uv);
				col.rgb = saturate(col.rgb + outline.rgb * _OutlineStrength * outline.a);
				// col.rgb = outline.rgb;
				return col;
			}
			ENDCG
		}
	}
}
