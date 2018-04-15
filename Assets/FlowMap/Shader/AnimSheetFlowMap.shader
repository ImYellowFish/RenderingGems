Shader "Unlit/AnimSheetFlowMap"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Column("Column", Int) = 1
		_Row("Row", Int) = 1
		_FrameRate("Framerate", Float) = 1

		[Header(Flow)] _FlowMap("Flow Map", 2D) = "grey" {}
		_FlowSpeed("Flow Speed", Float) = 1
		_FlowMag("Flow Magnitude", Float) = 1
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
				float4 uv0 : TEXCOORD0;
				float4 frame : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Column;
			float _Row;
			float _FrameRate;

			sampler2D _FlowMap;
			float _FlowSpeed;
			float _FlowMag;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				
				float reverseColumnCount = 1 / _Column;
				
				float2 uv0 = TRANSFORM_TEX(v.uv, _MainTex);

				// current and next frame index (unclamped)
				float frame0 = _Time.y * _FrameRate;
				float frame1 = _Time.y * _FrameRate + 1;

				// current frame row and column
				float row0 = fmod(floor(frame0 * reverseColumnCount), _Row);
				float column0 = floor(fmod(frame0, _Column));

				// current frame row and column
				float row1 = fmod(floor(frame1 * reverseColumnCount), _Row);
				float column1 = floor(fmod(frame1, _Column));

				//uv0.x = (uv0.x + column0) * reverseColumnCount;
				//uv0.y = (uv0.y + row0) * (1 / _Row);

				o.uv0 = float4(uv0, frame0, frac(frame0));
				o.frame = float4(column0, _Row - 1 - row0, column1, _Row - 1 - row1);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float2 reverseColumnRow = float2(1 / _Column, 1 / _Row);
				
				// current frame uv
				float2 uv0 = (i.uv0.xy + i.frame.xy) * reverseColumnRow;
				// next frame uv
				float2 uv1 = (i.uv0.xy + i.frame.zw) * reverseColumnRow;
				
				// apply flow distortion
				fixed4 flow0 = tex2D(_FlowMap, uv0);
				fixed frameFrac = i.uv0.w;

				uv0.x = uv0.x - (flow0.x - 0.5) * frameFrac * _FlowMag;
				uv0.y = uv0.y + (flow0.y - 0.5) * frameFrac * _FlowMag;

				fixed4 flow1 = tex2D(_FlowMap, uv1);
				uv1.x = uv1.x + (flow1.x - 0.5) * (1 - frameFrac) * _FlowMag;
				uv1.y = uv1.y - (flow1.y - 0.5) * (1 - frameFrac) * _FlowMag;

				// sample the texture
				fixed4 col0 = tex2D(_MainTex, uv0);
				fixed4 col1 = tex2D(_MainTex, uv1);
				fixed4 col = lerp(col0, col1, frameFrac);

				return col;
				// return col0;

			}
			ENDCG
		}
	}
}
