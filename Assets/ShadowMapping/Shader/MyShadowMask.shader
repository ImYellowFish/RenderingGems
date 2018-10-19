Shader "RGem/MyShadowMask"
{
	Properties
	{
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
			
			#include "UnityCG.cginc"
			float4x4 _MyShadowMatrixVP;

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 shadowPos : TEXCOORD1;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.shadowPos = o.vertex;
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				// TODO: encode depth to float
				#if defined(UNITY_REVERSED_Z)
					float depth = 1.0 - i.shadowPos.z / i.shadowPos.w;
				#else
					float depth = i.shadowPos.z / i.shadowPos.w;
				#endif
				return EncodeFloatRGBA(depth);
			}
			ENDCG
		}
	}
}
