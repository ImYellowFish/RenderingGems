Shader "RGem/Tessellation/TessellationDisplacementTest"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_CheckerBoardStrength("_CheckerBoardStrength", Range(0, 1)) = 1.0
		_WireframeWidth("_WireframeWidth", Range(0, 1)) = 0.02
		_MainColor("_MainColor", Color) = (0.5,0.5,0.5,1.0)
		//_TessellationUniform("_TessellationUniform", Range(1.0, 5.0)) = 1.0
		_TessellationEdgeWidth("_TessellationEdgeWidth", Float) = 10.0

		_TessDisplacementMap("_TessDisplacementMap", 2D) = "grey" {}
		_TessDisplacementStrength("_TessDisplacementStrength", Range(0, 10)) = 1.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma target 4.6 // for tessellation
			#define ENABLE_TESSELLATION_DISPLACEMENT

			struct VertexData
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct TessellationControlVertexData
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct InterpolatorsVertex
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				float4 shadowCoord : TEXCOORD3;
			};

			struct InterpolatorsGeometry
			{
				InterpolatorsVertex data;
				float3 barycentricCoordinates : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _CheckerBoardStrength;
			fixed4 _MainColor;
			float _WireframeWidth;

			// support shadow
			UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);

			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "TessellationUtils.cginc"

			#pragma vertex TestTessellationVertexProgram
			#pragma fragment frag
			#pragma hull TestHullProgram
			#pragma domain TestDomainProgram
			#pragma geometry WireframeGeometryProgram
			
			TessellationControlVertexData TestTessellationVertexProgram(VertexData v) {
				TessellationControlVertexData data;
				data.vertex = v.vertex;
				data.normal = v.normal;
				data.uv = v.uv;
				return data;
			}

			InterpolatorsVertex vert (VertexData v)
			{
				InterpolatorsVertex o;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.vertex = UnityWorldToClipPos(o.worldPos.xyz);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (InterpolatorsGeometry g) : SV_Target
			{				
				fixed4 col;
				InterpolatorsVertex i = g.data;
				
				// wireframe
				float minBary = min(min(g.barycentricCoordinates[0], g.barycentricCoordinates[1]), g.barycentricCoordinates[2]);
				float delta = abs(ddx(minBary)) + abs(ddy(minBary));
				float wireframe = saturate(step(_WireframeWidth * delta, minBary) + step(_WireframeWidth, 0.0001));

				// checkerboard
				float checkerboard = (frac(i.uv.x) - 0.5) * (frac(i.uv.y) - 0.5) > 0 ? 1.0 : (1 - _CheckerBoardStrength);

				// shadow
				fixed shadow = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, i.shadowCoord.xyz / i.shadowCoord.w);
				
				// directional lighting
				float3 lightDir = _WorldSpaceLightPos0.xyz - i.worldPos * _WorldSpaceLightPos0.w;
				float NdotL = saturate(dot(lightDir, i.worldNormal));
				float3 diffuse = _LightColor0 * _MainColor.rgb * NdotL;

				col.rgb = diffuse * checkerboard * wireframe * shadow;
				col.a = _MainColor.a;
				return col;
			}

			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual

			CGPROGRAM

			#pragma target 4.6 // for tessellation
			#define ENABLE_TESSELLATION_DISPLACEMENT

			struct VertexData
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct TessellationControlVertexData
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct InterpolatorsVertex
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				float4 shadowCoord : TEXCOORD3;
			};

			struct InterpolatorsGeometry
			{
				InterpolatorsVertex data;
				float3 barycentricCoordinates : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _CheckerBoardStrength;
			fixed4 _MainColor;
			float _WireframeWidth;

			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "TessellationUtils.cginc"

			#pragma vertex vert
			#pragma fragment frag
			#pragma hull TestHullProgram
			#pragma domain TestDomainProgramShadow
			#pragma geometry WireframeGeometryProgram

			TessellationControlVertexData vert(VertexData v) {
				TessellationControlVertexData data;
				data.vertex = v.vertex;
				data.normal = v.normal;
				data.uv = v.uv;
				return data;
			}

			fixed4 frag(InterpolatorsGeometry g) : SV_Target
			{
				return fixed4(1,1,1,1);
			}

			ENDCG
		}
	}
}
