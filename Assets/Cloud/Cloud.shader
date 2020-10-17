Shader "RGem/Cloud"
{
	Properties
	{
		_CloudTex ("Texture", 2D) = "white" {}
		_CloudLevel("Cloud Level", Vector) = (0,1,0,0)
		_CloudColor("Cloud Color", Color) = (0.5,0.5,0.5,1)
		_SkyColor("Sky Color", Color) = (0,0.25,0.5,1)
		_CloudVelocity("Cloud Velocity", Vector) = (0.1,0.1,0,0)
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
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _CloudTex;
			float4 _CloudTex_ST;
			float4 _CloudLevel;
			fixed4 _SkyColor;
			fixed4 _CloudColor;
			float4 _CloudVelocity;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _CloudTex);
				o.uv.zw = o.uv.xy + _CloudVelocity.zw * _Time.x;
				o.uv.xy = o.uv.xy + _CloudVelocity.xy * _Time.x;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 c1 = tex2D(_CloudTex, i.uv.xy);
				fixed4 c2 = tex2D(_CloudTex, i.uv.zw);
				float cloud_depth = smoothstep(_CloudLevel.x, _CloudLevel.y, c1.r * c2.g);
				fixed4 col = lerp(_SkyColor, _CloudColor, cloud_depth);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
