// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable

Shader "Unlit/DeferedDecal"
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
				UNITY_FOG_COORDS(1)
				float3 ray : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			// float4x4 _CameraToWorld;
			sampler2D_float _CameraDepthTexture;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.ray = UnityObjectToViewPos(v.vertex).xyz;
				o.screenPos = ComputeScreenPos(o.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screenPos);
				depth = LinearEyeDepth(depth);
				float4 vpos = float4(i.ray / i.ray.z * depth, 1.0);
				float3 wpos = mul(unity_CameraToWorld, vpos.xyz);
				float3 opos = mul(unity_WorldToObject, wpos.xyz);

				clip(0.5 - abs(opos.xyz));
				float2 uv = opos.xz + 0.5;
				
				// sample the texture
				fixed4 col = tex2D(_MainTex, uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
