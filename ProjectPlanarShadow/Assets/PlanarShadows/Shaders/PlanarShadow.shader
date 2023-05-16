Shader "Custom/PlanarShadow" 
{
	Properties 
	{
		_ShadowColor ("Shadow Color", Color) = (0,0,0,1)
		_PlaneHeight ("Plane Height", Float) = 0
		_MinimumLightDirectionY("Minimum Light Direction Y", Range(0.0, 1.0)) = 0.25
		[Toggle(_SAMPLE_PROBE_LIGHTING)] _UseProbeLighting("Sample Light Direction from Probes", Float) = 0
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

			//compile a variant that uses probe lighting instead of regular unity lighting
			#pragma shader_feature_local _SAMPLE_PROBE_LIGHTING

			// User-specified uniforms
			float4 _ShadowColor;
			float _PlaneHeight;
			float _MinimumLightDirectionY;

			struct appdata
			{
				float4 vertex : POSITION;

				//Single Pass Instancing Support
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct vertex_output
			{
				float4 vertex : SV_POSITION;

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

				o.vertex = UnityObjectToClipPos(v.vertex);

				float4 worldPosition = mul(unity_ObjectToWorld, v.vertex);

				//sample the light direction
				//we can sample from a regular unity light
				//or sample the dominant direction of light from light probes
				
				#if defined (_SAMPLE_PROBE_LIGHTING)
					float3 lightDirection = -normalize(GetDominantSphericalHarmoncsDirection()); //probe lighting
				#else
					float3 lightDirection = -normalize(_WorldSpaceLightPos0); //unity light source
				#endif

				float opposite = worldPosition.y - _PlaneHeight;

				//modified a bit slightly to include a clamp value.
				//this will control the length of the shadows especially when cast at grazing angles
				float cosTheta = clamp(-lightDirection.y, _MinimumLightDirectionY, 1.0);
				float hypotenuse = opposite / cosTheta;
				float3 vertexPosition = worldPosition.xyz + (lightDirection * hypotenuse);

				o.vertex = mul(UNITY_MATRIX_VP, float4(vertexPosition.x, _PlaneHeight, vertexPosition.z, 1));

				return o;
			}

			fixed4 fragment_base(vertex_output i) : COLOR
			{
				return _ShadowColor;
			}
			ENDCG
		}
	}
}
