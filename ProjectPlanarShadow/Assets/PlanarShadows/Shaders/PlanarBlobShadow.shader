	Shader "Custom/PlanarBlobShadow" 
{
	Properties 
	{
		[Header(Appearance)]
		_BlobColor ("Blob Color", Color) = (0,0,0,1)
		_BlobTexture ("Blob Shadow", 2D) = "white" {}

		[Header(Planar Properties)]
		_PlaneHeight("Plane Height", Float) = 0
		[Toggle(_STICK_TO_PLANE)] _UseStickToPlane("Stick Shadow To Plane", Float) = 1

		[Header(Distance Fade)]
		[Toggle(_DISTANCE_FADE)] _UseDistanceFade("Fade With Distance", Float) = 1
		_FadeHeight("Fade Height", Float) = 5
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

				//compile a variant that will fade the shadow with distance
				#pragma shader_feature_local _DISTANCE_FADE

				// User-specified uniforms
				sampler2D _BlobTexture;
				float4 _BlobColor;
				float _PlaneHeight;
				float _FadeHeight;

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
					float3 uv_heightFade : TEXCOORD0; //XY = UV, Z = Height Fade

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

					//set the final modified vertex position
					o.vertex = mul(UNITY_MATRIX_VP, float4(vertexWorldPosition.x, floorHeight, vertexWorldPosition.z, 1));
					
					//set the texcoord so we can map a blob texture
					o.uv_heightFade.xy = v.texcoord.xy;

					//for distance fading, we need a single float that we multiply with the alpha.
					//the farther the vertex is from the set plane, the more fade will be applied.
					#if defined (_DISTANCE_FADE)
						#if defined (_STICK_TO_PLANE)
							o.uv_heightFade.z = saturate((_PlaneHeight + _FadeHeight) - vertexWorldPosition.y);
						#else
							o.uv_heightFade.z = saturate(_FadeHeight - vertexWorldPosition.y);
						#endif
					#endif

					return o;
				}

				fixed4 fragment_base(vertex_output i) : COLOR
				{
					float4 blobShadow = tex2D(_BlobTexture, i.uv_heightFade.xy) * _BlobColor;

					#if defined (_DISTANCE_FADE)
						blobShadow.a *= i.uv_heightFade.z;
					#endif

					return blobShadow;
				}
				ENDCG
		}
	}
}
