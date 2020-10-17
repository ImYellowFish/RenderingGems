Shader "RGem/LightShaft/LightShaftShadowCaster"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull Off
		ZTest On
		ZWrite On
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
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 shadowPos : TEXCOORD1;
			};

			float _gLightShaftDepthBias;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.shadowPos = o.vertex;
				//o.shadowPos.z += _gLightShaftDepthBias;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float depth = i.shadowPos.z / i.shadowPos.w;
				#ifdef SHADER_TARGET_GLSL
					depth = 0.5 * depth + 0.5;
				#endif
				#ifdef UNITY_REVERSED_Z
					depth = 1.0 - depth;
				#endif
				return depth;
				return EncodeFloatRGBA(depth);
			}
			ENDCG
		}
	}
}
