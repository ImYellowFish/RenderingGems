Shader "RGem/Compute/SpringSurfaceShader" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
	}
		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 200

			CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma surface surf Standard fullforwardshadows
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling procedural:ConfigureSurface
			// #pragma editor_sync_compilation

			#pragma target 4.5

			sampler2D _MainTex;

			struct Input {
				float2 uv_MainTex;
			};

			half _Glossiness;
			half _Metallic;
			fixed4 _Color;
			float _ParticleStep;
			float _Resolution;
	#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
			StructuredBuffer<float3> _Positions;
	#endif
			void ConfigureSurface()
			{
				#if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
					float y = floor(unity_InstanceID / _Resolution);
					float x = unity_InstanceID - y * _Resolution;
					float3 dpos = _Positions[unity_InstanceID];
					float3 pos = float3(x, 0, y) * _ParticleStep;
					unity_ObjectToWorld = 0.0;
					unity_ObjectToWorld._m03_m13_m23_m33 = float4(dpos.xyz + pos.xyz, 1);
					unity_ObjectToWorld._m00_m11_m22 = _ParticleStep * 0.25;
				#endif
			}

			void surf(Input IN, inout SurfaceOutputStandard o) {
				// Albedo comes from a texture tinted by color
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				o.Albedo = IN.uv_MainTex.xyx * 0.25 + 0.25;
				// Metallic and smoothness come from slider variables
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;
				o.Alpha = c.a;
			}
			ENDCG
		}
			FallBack "Diffuse"
}
