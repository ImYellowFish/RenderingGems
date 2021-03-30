Shader "RGem/StencilOutline"
{
	Properties
	{
		_OutlineColor ("_OutlineColor", Color) = (1,1,1,1)
		_OutlineWidth ("_OutlineWidth", Float) = 0.1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			ZTest Off
			ColorMask 0

			// Mark stencil
			Stencil {
                Ref 2
                Comp always
                Pass replace
            }

			Color (1,1,1,1)
		}

		Pass
		{
			ZTest Off

			// Check stencil and draw object
			Stencil {
				Ref 2
				Comp NotEqual
				Pass Zero
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			fixed4 _OutlineColor;
			float _OutlineWidth;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex + v.normal * _OutlineWidth);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return _OutlineColor;
			}
			ENDCG
		}
	}
}
