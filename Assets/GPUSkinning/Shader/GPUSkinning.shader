Shader "RGem/GPUSkinning"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}

		_TslTex("Animation Translation Texture", 2D) = "white"{}
		_RotTex("Animation Rotation Texture", 2D) = "white"{}
		_TexWidth("Texture Width", Float) = 32
		_TexHeight("Texture Height", Float) = 32
		_FrameRate("Frame Rate", Range(0, 60)) = 30
		_BoneIndexOffset("Bone Index Offset", Float) = 0
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
			#pragma target 3.0

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float4 color : TEXCOORD2;
				float3 normal : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			sampler2D _TslTex;
			sampler2D _RotTex;

			float _TexWidth;
			float _TexHeight;
			float _FrameRate;
			float _BoneIndexOffset;

			inline float3 Rotate(float3 vertex, fixed4 c_rot) {
				float4 rot = c_rot * 2 - 1;
				// return vertex + rot.a * 2 * cross(rot.xyz, vertex);
				return vertex + 2.0 * cross(rot.xyz, cross(rot.xyz, vertex) + rot.w * vertex);
				// return vertex;
			}

			inline float3 Translate(float3 vertex, fixed4 c_tsl) {
				return vertex + (c_tsl.xyz - 0.5) * 16;
				// return vertex;
			}

			inline float3 GetSkinningPos(float time, float encodedBoneIndex, float3 vertexPos) {
				float4 animUV;
				animUV.x = (encodedBoneIndex * 64.0 + _BoneIndexOffset) / _TexWidth;
				animUV.y = 1.0 - (time * _FrameRate) / _TexHeight;
				animUV.y = 0.1;
				animUV.zw = 0;

				fixed4 c_tsl = tex2Dlod(_TslTex, animUV);
				fixed4 c_rot = tex2Dlod(_RotTex, animUV);

				float3 pos = Translate(Rotate(vertexPos, c_rot), c_tsl);
				return pos;
			}

			v2f vert (appdata v)
			{
				float4 pos;
				float time = _Time.y;
				pos.xyz = lerp(GetSkinningPos(time, v.color.r, v.vertex.xyz), 
					GetSkinningPos(time, v.color.b, v.vertex.xyz), 1.0 - v.color.g);
				pos.w = 1;

				v2f o;
				o.vertex = UnityObjectToClipPos(pos);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = (v.color.r * 64.0 + _BoneIndexOffset) / _TexWidth;
				o.normal = v.normal;

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				return i.color;
				fixed4 col = abs(dot(i.normal, float3(-0.5, 1.9, 0.5))) * 0.5;
				// fixed4 col = i.color;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
