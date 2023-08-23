// Cloudy Atmosphere
// by Silent

// This is a combination of various techniques to create a realistic sky shader.

// Using TowelCloud by 飛駒タオル
// https://gitlab.com/towelfunnelvrc/towelcloud/-/wikis/TowelCloud
// under Zlib license
// Using Bruneton's Improved Atmosphere
// https://github.com/ebruneton/precomputed_atmospheric_scattering
// under BSD 3-clause license
// Original port by Dan Shervheim - danielshervheim.com
// August 2019

Shader "Hidden/Silent/DSS/AtmosphericSkybox"
{
    Properties
    {
		_units_to_atmosphere_boundary ("Units to Atmosphere Boundary", float) = 6000
        [Enum(Off, 0, Clamp, 1, Mirror, 2)] clampViewVector("Clamp View At Horizon", Int) = 0

		_colorMultiplier ("Color Multiplier", Color) = (1,1,1,1)

		[Header(Moon)]
		_MoonColor("Moon Color", Color) = (0.2616284, 0.3708486, 0.6666667, 1.0)
		_MoonPosition("Moon Position and Distance", Vector) = (0.5689898, 0.4594319, -0.682036, 1.0)

		// Cloud parameters
		[Header(TowelCloud)]
		_noiseMap("Cloud Noise Map", 2D) = "white" {}
			_scale ("Cloud Size (Higher: less repetition)", Float) = 55
			_cloudy ("Cloudiness", Range (0, 1)) = 0.5
			_soft ("Cloud Softness", Range (0.0001, 0.9999)) = 0.4
		[Header(Horizon)]
		[Toggle]_underFade ("underFade: Fade out clouds at the bottom", Float) = 1
		_underFadeStart ("underFadeStart: Start fading position", Range (-1, 1)) = -0.5
		_underFadeWidth ("underFadeWidth: Fade gradient width", Range (0.0001, 0.9999)) = 0.2
		[Header(Movement)]
		_moveRotation ("moveRotation: Cloud movement direction", Range (0, 360)) = 0
		_speed_parameter ("speed: Cloud speed", Float) = 1
		_shapeSpeed_parameter ("shapeSpeed: Cloud deformation amount", Float) = 1
		_speedOffset ("speedOffset: Speed difference in fine parts of clouds", Float) = 0.2
		_speedSlide ("speedSlide: Lateral speed of fine parts of clouds", Float) = 0.1
		[Header(Rimlight)]
		_rimForce ("rimForce: Strength of edge light", Float) = 0.5
		_rimNarrow ("rimNarrow: Narrowness of edge light", Float) = 2
		[Header(Scattering)]
		[Toggle] _scattering ("scattering: Use diffuse light", Float) = 0
		_scatteringColor ("scatteringColor: Diffuse light color", Color) = (1, 1, 1, 1)
		_scatteringForce ("scatteringForce: Diffuse light strength", Range (0, 3)) = 0.8
		_scatteringRange ("scatteringRange: Range affected by diffuse light", Range (0, 1)) = 0.3
		_scatteringNarrow ("scatteringNarrow: Narrowness of diffuse light edge", Float) = 1
		[Header(Surface Wind)]
		_faceWindScale_parameter ("faceWindScale: Surface wind size", Float) = 1
		_faceWindForce_parameter ("faceWindForce: Surface wind strength", Float) = 1
		_faceWindMove ("faceWindMove: Surface wind movement speed", Float) = 1.3
		_faceWindMoveSlide ("faceWindMoveSlide: Movement speed of fine parts of surface wind", Float) = 1.8
		[Header(Distant Wind)]
		_farWindDivision ("farWindDivision: Number of divisions for distant wind", Int) = 35
		_farWindForce_parameter ("farWindForce: Distant wind strength", Float) = 1
		_farWindMove ("farWindMove: Distant wind movement speed", Float) = 2
		_farWindTopEnd ("farWindTopEnd: Position where distant wind disappears at the top", Float) = 0.5
		_farWindTopStart ("farWindTopStart: Position where distant wind starts to weaken at the top", Float) = 0.3
		_farWindBottomStart ("farWindBottomStart: Position where distant wind starts to weaken at the bottom", Float) = 0.1
		_farWindBottomEnd ("farWindBottomEnd: Position where distant wind disappears at the bottom", Float) = -0.1
		[Header(Airflow)]
		[Toggle] _stream ("stream: Airflow", Float) = 1
		_streamForce ("streamForce: Airflow strength", Float) = 5
		_streamScale ("streamScale: Airflow size", Float) = 5
		_streamMove ("streamMove: Airflow movement speed", Float) = 1.5
		[Header(Etc)]
		_fbmScaleUnder ("fbmScaleUnder: Deformation value of fine parts of clouds", Float) = 0.43
		_boost ("boost: Increase cloud light value", Float) = 1.1
		_chine ("chine: Softness of cloud ridges", Float) = 0.5
			//_alphaRate ("alphaRate 全体の透明度", Range (0, 1)) = 1

		// Textures.
		[HideInInspector] transmittance_texture("Transmittance", 2D) = "white" {}
		[HideInInspector] scattering_texture("Scattering", 3D) = "white" {}
		[HideInInspector] single_mie_scattering_texture("Single Mie Scattering", 3D) = "white" {}
		[HideInInspector] irradiance_texture("Irradiance", 2D) = "white" {}

		// Parameters.
		[HideInInspector] exposure("exposure", Float) = 0.0001
		[HideInInspector] white_point("white_point", Vector) = (1.180388, 0.9290531, 0.8905591)
		[HideInInspector] earth_center("earth_center", Vector) = (0,0,0)  // todo: hide
		[HideInInspector] sun_size("sun_size", Vector) = (0.004675034, 0.9999891, 0)

		// Advanced parameters.
		[HideInInspector] sun_angular_radius("sun_angular_radius", Float) = 0.004675034
		[HideInInspector] bottom_radius("bottom_radius", Float) = 6360
		[HideInInspector] top_radius("top_radius", Float) = 6420
		[HideInInspector] mie_phase_function_g("mie_phase_function_g", Range(-1, 1)) = 0.8
		[HideInInspector] mu_s_min("mu_s_min", Float) = -0.207911
		[HideInInspector] SKY_SPECTRAL_RADIANCE_TO_LUMINANCE("SKY_SPECTRAL_RADIANCE_TO_LUMINANCE", Vector) = (0, 0, 0)
		[HideInInspector] SUN_SPECTRAL_RADIANCE_TO_LUMINANCE("SUN_SPECTRAL_RADIANCE_TO_LUMINANCE", Vector) = (0, 0, 0)
		[HideInInspector] solar_irradiance("solar_irradiance", Vector) = (1.5, 1.5, 1.5)
		[HideInInspector] rayleigh_scattering("rayleigh_scattering", Vector) = (0.005802339, 0.01355776, 0.03310001)
		[HideInInspector] mie_scattering("mie_scattering", Vector) = (0.003996, 0.003996, 0.003996)

		// Texture properties.
		[HideInInspector] TRANSMITTANCE_TEXTURE_WIDTH("TRANSMITTANCE_TEXTURE_WIDTH", Int) = 256
		[HideInInspector] TRANSMITTANCE_TEXTURE_HEIGHT("TRANSMITTANCE_TEXTURE_HEIGHT", Int) = 64
		[HideInInspector] SCATTERING_TEXTURE_R_SIZE("SCATTERING_TEXTURE_R_SIZE", Int) = 32
		[HideInInspector] SCATTERING_TEXTURE_MU_SIZE("SCATTERING_TEXTURE_MU_SIZE", Int) = 128
		[HideInInspector] SCATTERING_TEXTURE_MU_S_SIZE("SCATTERING_TEXTURE_MU_S_SIZE", Int) = 32
		[HideInInspector] SCATTERING_TEXTURE_NU_SIZE("SCATTERING_TEXTURE_NU_SIZE", Int) = 8
		[HideInInspector] SCATTERING_TEXTURE_WIDTH("SCATTERING_TEXTURE_WIDTH", Int) = 256
		[HideInInspector] SCATTERING_TEXTURE_HEIGHT("SCATTERING_TEXTURE_HEIGHT", Int) = 128
		[HideInInspector] SCATTERING_TEXTURE_DEPTH("SCATTERING_TEXTURE_DEPTH", Int) = 32
		[HideInInspector] IRRADIANCE_TEXTURE_WIDTH("IRRADIANCE_TEXTURE_WIDTH", Int) = 64
		[HideInInspector] IRRADIANCE_TEXTURE_HEIGHT("IRRADIANCE_TEXTURE_HEIGHT", Int) = 16
    }
    SubShader
    {
		Tags
		{
			"Queue" = "Background"
			"RenderType" = "Background"
			"PreviewType" = "Skybox"
			"IsEmissive" = "true"
		}

		Cull Off ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_local __ RADIANCE_API_ENABLED
			#pragma multi_compile_local __ COMBINED_SCATTERING_TEXTURES
			#pragma shader_feature_local __ _STREAM_ON

			#define USE_STARS
			#define USE_CLOUDS

			#include "UnityCG.cginc"
			#include "Definitions.cginc"
			#include "UtilityFunctions.cginc"
			#include "TransmittanceFunctions.cginc"
			#include "ScatteringFunctions.cginc"
			#include "IrradianceFunctions.cginc"
			#include "RenderingFunctions.cginc"
			#include "CloudFunctions.cginc"
			#include "NightSkyFunctions.cginc"

            float _units_to_atmosphere_boundary;
            uint clampViewVector;

			// Textures.
			sampler2D transmittance_texture;
			sampler3D scattering_texture;
			sampler3D single_mie_scattering_texture;
			sampler2D irradiance_texture;

			// Parameters.
			float exposure;
			float3 white_point;
			float3 earth_center;
			float2 sun_size;

			float3 _colorMultiplier;
			float3 groundColor;

			float4 _MoonColor;
			float4 _MoonPosition;

			// Unity inbuilt parameters.
			float4 _LightColor0;

			// Advanced parameters and texture properties are in Definitions.cginc.

			struct appdata
			{
				float4 vertex : POSITION;
				float3 uvw : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
                float3 view_ray : TEXCOORD0;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.view_ray = v.uvw;
				return o;
			}

			#ifdef RADIANCE_API_ENABLED
				RadianceSpectrum GetSolarRadiance()
				{
					return solar_irradiance / (PI * sun_angular_radius * sun_angular_radius);
				}

				RadianceSpectrum GetSkyRadiance(Position camera, Direction view_ray, Length shadow_length,
				Direction sun_direction, out DimensionlessSpectrum transmittance)
				{
					return GetSkyRadiance(transmittance_texture,
						scattering_texture, single_mie_scattering_texture,
						camera, view_ray, shadow_length, sun_direction, transmittance);
				}

			RadianceSpectrum GetSkyRadianceToPoint(
				Position camera, Position _point, Length shadow_length,
				Direction sun_direction, out DimensionlessSpectrum transmittance) 
			{
				return GetSkyRadianceToPoint(transmittance_texture,
					scattering_texture, single_mie_scattering_texture,
					camera, _point, shadow_length, sun_direction, transmittance);
			}

			IrradianceSpectrum GetSunAndSkyIrradiance(
				Position p, Direction normal, Direction sun_direction,
				out IrradianceSpectrum sky_irradiance) 
			{
				return GetSunAndSkyIrradiance(transmittance_texture,
					irradiance_texture, p, normal, sun_direction, sky_irradiance);
			}
			#else
				Luminance3 GetSolarRadiance()
				{
					return solar_irradiance / (PI * sun_angular_radius * sun_angular_radius) *
						SUN_SPECTRAL_RADIANCE_TO_LUMINANCE;
				}

				Luminance3 GetSkyRadiance(Position camera, Direction view_ray, Length shadow_length,
				Direction sun_direction, out DimensionlessSpectrum transmittance)
				{
					return GetSkyRadiance(
						transmittance_texture,
						scattering_texture, single_mie_scattering_texture,
						camera, view_ray, shadow_length, sun_direction, transmittance) *
						SKY_SPECTRAL_RADIANCE_TO_LUMINANCE;
				}

			Luminance3 GetSkyRadianceToPoint(
				Position camera, Position _point, Length shadow_length,
				Direction sun_direction, out DimensionlessSpectrum transmittance) 
			{
				return GetSkyRadianceToPoint(transmittance_texture,
					scattering_texture, single_mie_scattering_texture,
					camera, _point, shadow_length, sun_direction, transmittance) *
					SKY_SPECTRAL_RADIANCE_TO_LUMINANCE;
			}

			Illuminance3 GetSunAndSkyIrradiance(
				Position p, Direction normal, Direction sun_direction,
				out IrradianceSpectrum sky_irradiance) 
			{
				IrradianceSpectrum sun_irradiance = GetSunAndSkyIrradiance(
					transmittance_texture, irradiance_texture, p, normal,
					sun_direction, sky_irradiance);
				sky_irradiance *= SKY_SPECTRAL_RADIANCE_TO_LUMINANCE;
				return sun_irradiance * SUN_SPECTRAL_RADIANCE_TO_LUMINANCE;
			}
			#endif


			fixed4 frag(v2f i) : SV_Target
			{
				float3 view_position = _WorldSpaceCameraPos + earth_center;
				float3 view_direction = normalize(i.view_ray);
				float3 view_direction_stars = view_direction;

                if (clampViewVector == 1)
                {
                    view_direction.y = saturate(view_direction.y);
                }
				if (clampViewVector == 2 && view_direction.y < 0)
				{
					view_direction.y *= -1;
				}

				float3 sun_direction = _WorldSpaceLightPos0.xyz;
				float shadow_length = 0;
				float3 radiance;
				float3 transmittance;
				float3 cloudRadiance;
				float3 cloudTransmittance;

                float3 p = view_position;
                p /= _units_to_atmosphere_boundary;
                p *= (top_radius - bottom_radius);
                p.y += bottom_radius;

				// It seems like calculating the clouds first would be the faster path to take.
				// By calculating the clouds first, we can avoid needing to sample sky radiance
				// twice. Still, sampling sky radiance shouldn't be expensive...
#if defined(USE_CLOUDS)
				CloudOutputData cloudData = GetCloudAtmosphere(p, -view_direction, sun_direction, transmittance,
					transmittance_texture, scattering_texture);
				float3 cloudWorldNormal = cloudData.cloudWorldNormal;
				float cloudPower = cloudData.cloudPower;
				float cloudAreaRate = cloudData.cloudAreaRate;
					
				// Calculate light and shadow effects from each dot
				float3 invY = float3(1, -1, 1);
				float3 skyVector = float3(1, 0, 0);
				float3 cloudLightDirection = sun_direction; //invY*-reflect(sun_direction, skyVector);
				float normalDot = dot(cloudWorldNormal, cloudLightDirection);
				float normalDotForUv = saturate(normalDot * 0.5 + 0.5);
				float viewDotToLightForUv = dot(view_direction, cloudLightDirection) * 0.5 + 0.5;
				float viewDotToSkyForUv = dot(view_direction, skyVector) * 0.5 + 0.5;
				float cloudOcclusion = 1-(normalDotForUv * cloudPower);
				
				// Get the cloud colour from the colour of the atmosphere when it's at
				// maximum density.
				float3 cloudViewDir = float3(view_direction.x, 0, view_direction.z);
				float3 cloudP = float3(0, 
					(top_radius - bottom_radius) / _units_to_atmosphere_boundary
					 * view_position.y + bottom_radius, 
					0);

				cloudRadiance = (cloudPower > 0.0) 
					? GetSkyRadiance(cloudP, cloudViewDir, 0, cloudLightDirection, 
					cloudTransmittance)
					: 1.0;

				radiance = (cloudPower < 1.0)
					? GetSkyRadiance(p, view_direction, shadow_length, sun_direction, 
					transmittance)
					: cloudRadiance;
#else
				radiance = GetSkyRadiance(p, view_direction, shadow_length, sun_direction, 
					transmittance);
#endif
				// If the view ray intersects the Sun, add the Sun radiance.
				// Note that there are two ways of handling the sun colour.
				// When baking reflection probes, the skybox is not told the colour of the sun
				// to avoid doubled sun reflections. However, this can look bad visually, especially
				// when a realtime light is not present in the scene. To avoid this, Unity's regular
				// procedural skybox uses this workaround which clamps the max intensity of the
				// sky's sun. This isn't desirable for all scenarios though.
            	half lightColorIntensity = clamp(length(_LightColor0.xyz), 0.25, 1) ;
				float sunAttenuation = smoothstep(sun_size.y, 1, dot(view_direction, sun_direction));
				float3 sunRadiance = transmittance * GetSolarRadiance() * (_LightColor0.xyz / lightColorIntensity); //* 1e-4 
				if (sunAttenuation > 0)
				{
					radiance += sunAttenuation *  sunRadiance;
				}

				// Todo: Finish re-adding moon.
				// Night radiance
				// This is a total hack; it just looks nicer than pure black.
				float3 nightRadiance = getNightHaze(view_position, view_direction_stars, sun_direction);

				float cloudDampening = saturate(dot(float3(0, 1, 0), sun_direction));

#if defined(USE_CLOUDS)
				float3 sunColorClouds = sunRadiance * 1e-5;
				float3 nightCloudCol = 1e-6 * GetSolarRadiance() * _MoonColor;

				cloudRadiance += normalDotForUv * sunColorClouds * cloudDampening;

				// Add rim light and transmission to clouds
				
				// == 境界が光る度合いを用意
					float rimPowerR = cloudAreaRate * _rimNarrow;
					rimPowerR = quadOut(saturate(rimPowerR));
					float rimPower = (1 - rimPowerR) * _rimForce;
					rimPower = saturate(rimPower);
					// 境界の光の色を設定
					//float2 rimUv = float2(viewDotToLightForUv, normalDotForUv);
					//float3 rimColor =  transmittance;
					//cloudRadiance.rgb =  rimColor.rgb * rimPower + cloudRadiance.rgb;
					float3 rimAddColor = (1-normalDotForUv) * transmittance 
						* cloudPower * _rimForce * rimPower;
					cloudRadiance += 1e-5 * rimAddColor * GetSolarRadiance();
				// == 透過拡散光
					float scatteringPower = 0;
					if (_scattering)
					{
						float scatteringPowerR = cloudAreaRate * _scatteringNarrow;
						scatteringPowerR = quadOut(saturate(scatteringPowerR));
						float scatteringPower = (1 - scatteringPowerR) * _scatteringForce;
						// 範囲を限定する
						float scatteringPowerRateRaw = saturate((_scatteringRange - viewDotToLightForUv) / _scatteringRange);
						if (_scatteringRange == 0)	// ゼロ除算回避
						{
							scatteringPowerRateRaw = 0;
						}
						// 境界を丸く
						scatteringPower *= quadIn(scatteringPowerRateRaw);
						scatteringPower = saturate(scatteringPower);
						// 合成
						cloudRadiance.rgb += scatteringPower * transmittance 
							* _scatteringForce * sunColorClouds;
						nightCloudCol.rgb += (scatteringPower * transmittance
							* nightCloudCol);
					}
#endif
				// Add stars.
				// In real life, stars are always visible, but the atmosphere is too 
				// bright for us to see them. However, dealing with realistic
				// light ranges in Unity (let alone VRchat) is a huge pain. Instead,
				// let's fake it. 
				float atmosLuma = dot(radiance, 1.0/3.0);
				float3 nightSky = getNightSky(view_position, view_direction_stars);

				nightSky *= GetSolarRadiance() * 1e-5;
				nightSky += nightRadiance * 10;

#if defined(USE_CLOUDS)
				nightSky += nightCloudCol * (1-cloudOcclusion);
				nightSky *= (1-cloudPower);
#endif

#if defined(USE_STARS)
				radiance += nightSky / max(1, atmosLuma/50);
#endif


#if defined(USE_CLOUDS)
				// Finish applying cloud colour. 
				radiance = lerp(radiance, cloudRadiance, saturate(cloudPower));
#endif
				//radiance = lerp(radiance, ground_radiance, ground_alpha);
				
                radiance = (radiance/white_point)*exposure;
				// radiance += max(0, normalDotForUv * sunColorClouds) * saturate(cloudPower) + rimAddColor;

				radiance *= _colorMultiplier.rgb;

				return float4(radiance, 1);
			}
            ENDCG
        }
    }
}
