Shader "RGem/PlanarShadowReciever"
{
	// Write a specific stencil value, which the planar shadow uses for masking
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque"}
		LOD 100
		Pass
		{
			Name "ShadowReceiver"
			// ColorMask 0

			Stencil
			{
				// Writes a specific stencil value
				Ref 1 // shadow receiver
				Comp Always
				Pass Replace
				Fail Keep
				ZFail Keep
				ReadMask 1
				WriteMask 1
			}

			
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

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				return fixed4(0.5,0.5,0,1);
			}
			ENDCG
		}
	}
}
