Shader "RGem/PlanarShadow"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_GroundHeight ("Ground Height", Float) = 0
		_ShadowDirection ("Shadow Direction", Vector) = (1, -1, 1, 0)
		_ShadowColor ("Shadow Color", Color) = (0,0,0,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Name "Shadow"
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			float _GroundHeight;
			float4 _ShadowDirection;
			fixed4 _ShadowColor;

			struct appdata
			{
				float4 vertex : POSITION;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				float3 shadowDir = normalize(_ShadowDirection.xyz);
				float3 shadowWorldPos = worldPos + shadowDir * (_GroundHeight - worldPos.y) / (shadowDir.y + 1e-5);
				o.vertex = mul(UNITY_MATRIX_VP,float4(shadowWorldPos, 1));
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				return _ShadowColor;
			}
			ENDCG
		}

		Pass
		{
			//// With reversed Y, Cull result will be reverted too.
			// Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float3 normal: TEXCOORD2;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = normalize(mul(UNITY_MATRIX_M, v.normal));
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = dot(i.normal, float3(0.1, 0.8, -0.7)) * 0.5 + 0.5;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
