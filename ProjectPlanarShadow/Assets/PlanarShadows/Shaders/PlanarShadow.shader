Shader "Custom/PlanarShadow" 
{
	Properties 
	{
		[Header(Appearance)]
		_ShadowColor ("Shadow Color", Color) = (0,0,0,1)

		[Header(Planar Properties)]
		_PlaneHeight ("Plane Height", Float) = 0
		_MinimumLightDirectionY("Minimum Light Direction Y", Range(0.0, 1.0)) = 0.25
		[Toggle(_SAMPLE_PROBE_LIGHTING)] _UseProbeLighting("Sample Light Direction from Probes", Float) = 0
		[Toggle(_STICK_TO_PLANE)] _UseStickToPlane("Stick Shadow To Plane", Float) = 1

		[Header(Distance Fade)]
		[Toggle(_DISTANCE_FADE)] _UseDistanceFade("Fade With Distance", Float) = 1
		_FadeHeight("Fade Height", Float) = 5
	}

	SubShader 
	{
		Tags 
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"LightMode" = "ForwardBase"
		}

		Pass 
		{   
			Cull Off
			ZWrite On
			ZTest LEqual 
			Blend SrcAlpha OneMinusSrcAlpha
			
			Stencil 
			{
				Ref 0
				Comp Equal
				Pass IncrWrap
				ZFail Keep
			}

			CGPROGRAM
			#include "UnityCG.cginc"
			#pragma vertex vertex_base
			#pragma fragment fragment_base

			#pragma multi_compile_instancing

			//compile a variant that uses probe lighting instead of regular unity lighting
			#pragma shader_feature_local _SAMPLE_PROBE_LIGHTING

			//compile a variant that will stick the shadow to a plane (rather than have it float with the object)
			#pragma shader_feature_local _STICK_TO_PLANE

			//compile a variant that will fade the shadow with distance
			#pragma shader_feature_local _DISTANCE_FADE

			// User-specified uniforms
			float4 _ShadowColor;
			float _PlaneHeight;
			float _MinimumLightDirectionY;
			float _FadeHeight;

			struct appdata
			{
				float4 vertex : POSITION;

				//Single Pass Instancing Support
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct vertex_output
			{
				float4 vertex : SV_POSITION;
				float heightFade : TEXCOORD0;

				//Single Pass Instancing Support
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#if defined (_SAMPLE_PROBE_LIGHTING)
			float3 GetDominantSphericalHarmoncsDirection()
			{
				//start with adding the L1 bands from the spherical harmonics probe to get our main direction (2 order SH)
				float3 sphericalHarmonics_dominantDirection = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;

				//(this isn't required, but helps)
				//add the L2 bands for better precision (adding it makes it 3 order SH)
				sphericalHarmonics_dominantDirection += unity_SHBr.xyz + unity_SHBg.xyz + unity_SHBb.xyz + unity_SHC;

				return sphericalHarmonics_dominantDirection;
			}
			#endif

			vertex_output vertex_base(appdata v)
			{
				vertex_output o;

				//Single Pass Instancing Support
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(vertex_output, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				/*
					sample the light direction.
					we can sample from a regular unity light,
					or sample the dominant direction of light from light probes.
				*/
				#if defined (_SAMPLE_PROBE_LIGHTING)
					float3 lightDirection = -normalize(GetDominantSphericalHarmoncsDirection()); //probe lighting
				#else
					float3 lightDirection = -normalize(_WorldSpaceLightPos0); //unity light source
				#endif

				//modified a bit slightly to include a clamp value.
				//this will control the length of the shadows especially when cast at grazing angles
				float cosTheta = clamp(-lightDirection.y, _MinimumLightDirectionY, 1.0);

				//we will be working in world space to convert vertex from object space to world space.
				float4 vertexWorldPosition = mul(unity_ObjectToWorld, v.vertex);

				//for these cases, we will need the object origin position
				//for when _STICK_TO_PLANE is toggled off, the plane will be at the mesh origin
				//for when _DISTANCE_FADE is toggled on, distance will be measured from the mesh origin (rather than each vertex because that will cause some artifacts, we want it to look consistent)
				#if !defined (_STICK_TO_PLANE) || (_DISTANCE_FADE)
					float4 meshOriginWorldPosition = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
				#endif
				/*
					set the floor height according to what the user wants.
					the classic way is to stick it to a plane,
					but also if they want, we'll give them the option to just have it float with the object origin (does go against what the main effect is about, but let them have their fun)
				*/
				#if defined (_STICK_TO_PLANE)
					float floorHeight = _PlaneHeight;
				#else
					float floorHeight = meshOriginWorldPosition.y + _PlaneHeight;
				#endif

				//using trigonometry, calculate where the vertex position will be displaced to according to the light direction
				float opposite = vertexWorldPosition.y - floorHeight;
				float hypotenuse = opposite / cosTheta;

				//offset the vertex position according to the light direction and the length of the hypotenuse (so that it basically stretches out).
				float3 offsetVertexWorldPosition = vertexWorldPosition.xyz + (lightDirection * hypotenuse);

				//set the final modified vertex position
				o.vertex = mul(UNITY_MATRIX_VP, float4(offsetVertexWorldPosition.x, floorHeight, offsetVertexWorldPosition.z, 1));

				//for distance fading, we need a single float that we multiply with the alpha.
				//the farther the vertex is from the set plane, the more fade will be applied.
				#if defined (_DISTANCE_FADE)
					#if defined (_STICK_TO_PLANE)
						o.heightFade = saturate((_PlaneHeight + _FadeHeight) - meshOriginWorldPosition.y);
					#else
						o.heightFade = saturate(_FadeHeight - meshOriginWorldPosition.y);
					#endif
				#endif

				return o;
			}

			fixed4 fragment_base(vertex_output i) : COLOR
			{
				#if defined (_DISTANCE_FADE)
					return float4(_ShadowColor.rgb, _ShadowColor.a * i.heightFade);
				#else
					return _ShadowColor;
				#endif
			}
			ENDCG
		}
	}
}
