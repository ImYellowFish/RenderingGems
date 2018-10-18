﻿Shader "RGem/MyShadowMask"
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

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				// TODO: encode depth to float
				#if defined(UNITY_REVERSED_Z)
					float depth = 1.0 - i.vertex.z;
				#else
					float depth = i.vertex.z;
				#endif
				return EncodeFloatRGBA(depth);
			}
			ENDCG
		}
	}
}
