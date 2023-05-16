Shader "Custom/PlanarBlobShadow" 
{
	Properties 
	{
		_BlobColor ("Blob Color", Color) = (0,0,0,1)
		_BlobTexture ("Blob Shadow", 2D) = "white" {}
		_PlaneHeight("Plane Height", Float) = 0
		[Toggle(_STICK_TO_PLANE)] _UseStickToPlane("Stick Shadow To Plane", Float) = 1
	}

		SubShader
		{
			Tags
			{
				"Queue" = "Transparent+1"
				"IgnoreProjector" = "True"
				"RenderType" = "Transparent"
			}

			Pass
			{
				Cull Off
				ZWrite On
				Blend SrcAlpha OneMinusSrcAlpha

				CGPROGRAM
				#include "UnityCG.cginc"
				#pragma vertex vertex_base
				#pragma fragment fragment_base

				#pragma multi_compile_instancing

				//compile a variant that will stick the shadow to a plane (rather than have it float with the object)
				#pragma shader_feature_local _STICK_TO_PLANE

				// User-specified uniforms
				sampler2D _BlobTexture;
				float4 _BlobColor;
				float _PlaneHeight;

				struct appdata
				{
					float4 vertex : POSITION;
					float2 texcoord : TEXCOORD0;

					//Single Pass Instancing Support
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct vertex_output
				{
					float4 vertex : SV_POSITION;
					float2 uv : TEXCOORD0;

					//Single Pass Instancing Support
					UNITY_VERTEX_OUTPUT_STEREO
				};

				vertex_output vertex_base(appdata v)
				{
					vertex_output o;

					//Single Pass Instancing Support
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_INITIALIZE_OUTPUT(vertex_output, o);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

					//we will be working in world space to convert vertex from object space to world space.
					float4 vertexWorldPosition = mul(unity_ObjectToWorld, v.vertex);

					/*
						set the floor height according to what the user wants.
						the classic way is to stick it to a plane,
						but also if they want, we'll give them the option to just have it float with the object origin (does go against what the main effect is about, but let them have their fun)
					*/
					#if defined (_STICK_TO_PLANE)
						float floorHeight = _PlaneHeight;
					#else
						float floorHeight = mul(unity_ObjectToWorld, float4(0.0, _PlaneHeight, 0.0, 1.0)).y;
					#endif

					o.vertex = mul(UNITY_MATRIX_VP, float4(vertexWorldPosition.x, floorHeight, vertexWorldPosition.z, 1));
					o.uv = v.texcoord;

					return o;
				}

				fixed4 fragment_base(vertex_output i) : COLOR
				{
					return tex2D(_BlobTexture, i.uv) * _BlobColor;
				}
				ENDCG
		}
	}
}
