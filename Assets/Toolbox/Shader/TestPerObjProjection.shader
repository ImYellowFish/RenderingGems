Shader "RGem/Toolbox/TestPerObjProjection"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

		[Enum(Normal,1,GLState,2,CameraProj,3,GLGPUProj,4,GLGPUProjRT,5,InvProj,6,InvY,7)]
		_TestMode("Test Mode", Float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

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
			float _TestMode;
			float4x4 _GLGPUProjMatrix;
			float4x4 _GLGPUProjRTMatrix;
			
			v2f vert (appdata v)
			{
				v2f o;
				if (_TestMode < 1.1) {
					o.vertex = UnityObjectToClipPos(v.vertex);
				}
				else if (_TestMode < 2.1) {
					o.vertex = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_MV, v.vertex));
				}
				else if (_TestMode < 3.1) {
					o.vertex = mul(unity_CameraProjection, mul(UNITY_MATRIX_MV, v.vertex));
				}
				else if (_TestMode < 4.1) {
					o.vertex = mul(_GLGPUProjMatrix, mul(UNITY_MATRIX_MV, v.vertex));
				}
				else if (_TestMode < 5.1) {
					o.vertex = mul(_GLGPUProjRTMatrix, mul(UNITY_MATRIX_MV, v.vertex));
				}
				else if (_TestMode < 6.1) {
					o.vertex = UnityObjectToClipPos(v.vertex);
					float4 viewPos = mul(unity_CameraInvProjection, o.vertex);
					// o.vertex = mul(UNITY_MATRIX_P, viewPos); // wrong. Must use cameraProjection.
					o.vertex = mul(unity_CameraProjection, viewPos);
				}
				else if (_TestMode < 7.1) {
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.vertex.y = -o.vertex.y;
				}
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = mul(UNITY_MATRIX_M, v.normal);
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
