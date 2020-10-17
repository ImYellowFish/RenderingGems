Shader "RGem/MyShadowReceiver"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ShadowBaseOffset("Shadow Base Offset", Float) = 0.01
		_ShadowSlopeOffset("Shadow Slope Offset", Float) = 0.01
		_ShadowColor("Shadow Color", Float) = 0.5
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
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 shadowSpacePos: TEXCOORD1;
				float3 worldNormal: TEXCOORD2;
			};

			sampler2D _MainTex;
			
			Texture2D _MyShadowTex;
			SamplerState sampler_MyShadowTex;
			
			float4 _MainTex_ST;
			float4 _MyShadowLightDir;
			float4x4 _MyShadowMatrixVP;
			float _ShadowBaseOffset;
			float _ShadowSlopeOffset;
			float _ShadowColor;

			v2f vert (appdata v)
			{
				v2f o;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.vertex = mul(UNITY_MATRIX_VP, worldPos);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.shadowSpacePos = mul(_MyShadowMatrixVP, worldPos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float2 shadowUV = (i.shadowSpacePos.xy / i.shadowSpacePos.w) * 0.5 + 0.5;
				#if UNITY_UV_STARTS_AT_TOP
					shadowUV.y = 1.0 - shadowUV.y;
				#endif

				float objDepth = i.shadowSpacePos.z / i.shadowSpacePos.w;
				float shadowMapDepth = _MyShadowTex.Sample(sampler_MyShadowTex, shadowUV); //DecodeFloatRGBA(tex2D(_MyShadowTex, shadowUV));
				return float4(shadowMapDepth, shadowMapDepth, shadowMapDepth, 1);

				#if defined(UNITY_REVERSED_Z)
					objDepth = 1.0 - objDepth;
				#endif

				float cos_normal_lightDir = dot(_MyShadowLightDir.xyz, normalize(i.worldNormal));
				float sin_normal_lightDir = sqrt(1.0 - cos_normal_lightDir * cos_normal_lightDir);
				float shadowOffset = _ShadowSlopeOffset * sin_normal_lightDir + _ShadowBaseOffset;

				float inShadow = step(shadowMapDepth + shadowOffset, objDepth);
				fixed4 col = cos_normal_lightDir * 0.5 + 0.8;
				return col * (1.0 - inShadow * _ShadowColor);
			}
			ENDCG
		}
		
		//UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}
