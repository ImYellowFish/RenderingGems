Shader "RGem/Test/PlayWithDepth"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_DepthMag ("Depth Magnitude", Range(-3, 3)) = 1
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
				float4 vertex : SV_POSITION;
				float depth : TEXCOORD1;
				float4 viewPos : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _DepthMag;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				
				float4 depth_pos;

				float4 viewPos = mul(UNITY_MATRIX_MV, v.vertex);
				o.viewPos = viewPos;

				float4 viewPosTueak = viewPos + float4(0, 0, 1, 0);
				float4 glProjPos = mul(unity_CameraProjection, viewPosTueak);
				
				// homo space z
				depth_pos = o.vertex;
				// o.depth = o.vertex.z;
				
				// gl proj
				depth_pos = glProjPos;

				// view space z
				//depth_pos = viewPos;

				o.depth = depth_pos.z / depth_pos.w;
				
				//// matrix peek
				//o.depth = unity_CameraProjection._34;

				// param peek
				o.depth = _ProjectionParams.x;
				o.depth = UNITY_MATRIX_P._22;
				o.depth = _ZBufferParams.x;

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// hpos z
				float hpos_z = i.depth;
				hpos_z = -i.viewPos.z;
				hpos_z = hpos_z * _DepthMag;
				// hpos_z = hpos_z * 0.5 + 0.5;
				return float4(hpos_z, hpos_z, hpos_z, 1);
			}
			ENDCG
		}
	}
}
