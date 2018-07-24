Shader "RGem/GPUSkinning"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}

		_TslTex("Animation Translation Texture", 2D) = "white"{}
		_RotTex("Animation Rotation Texture", 2D) = "white"{}
		_TexWidth("Texture Width", Float) = 32
		_TexHeight("Texture Height", Float) = 32
		_FrameRate("Frame Rate", Range(1, 60)) = 30
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma target 3.0

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float4 color : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			sampler2D _TslTex;
			sampler2D _RotTex;

			float _TexWidth;
			float _TexHeight;
			float _FrameRate;

			inline float3 Rotate(float3 vertex, fixed4 c_rot) {
				float4 rot = c_rot * 2 - 1;
				// return vertex + rot.a * 2 * cross(rot.xyz, vertex);
				return vertex + 2.0 * cross(rot.xyz, cross(rot.xyz, vertex) + rot.w * vertex);
				// return vertex;
			}

			inline float3 Translate(float3 vertex, fixed4 c_tsl) {
				return vertex + (c_tsl.xyz - 0.5) * 4;
				// return vertex;
			}

			v2f vert (appdata v)
			{
				float4 animUV;
				animUV.x = (v.color.r * 32.0) / _TexWidth;
				animUV.y = (_Time.y * _FrameRate - 0.5) / _TexHeight;
				animUV.zw = 0;

				fixed4 c_tsl = tex2Dlod(_TslTex, animUV);
				fixed4 c_rot = tex2Dlod(_RotTex, animUV);

				float4 pos;
				pos.xyz = Translate(Rotate(v.vertex.xyz, c_rot), c_tsl);
				pos.w = 1;

				v2f o;
				o.vertex = UnityObjectToClipPos(pos);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = c_tsl;

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				// fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 col = i.color;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
