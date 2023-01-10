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
		units_to_atmosphere_boundary ("Units to Atmosphere Boundary", float) = 6000
        [Toggle] tonemap("Tonemap", Int) = 1
        [Toggle] gammaCorrection("Gamma Correction", Int) = 0
        [Enum(Off, 0, Clamp, 1, Mirror, 2)] clampViewVector("Clamp View At Horizon", Int) = 0

		colorMultiplier ("Color Multiplier", Color) = (1,1,1,1)

		
		[Header(moon)]
		_MoonColor("Moon Color", Color) = (0.2616284, 0.3708486, 0.6666667, 1.0)
		_MoonPosition("Moon Position and Distance", Vector) = (0.5689898, 0.4594319, -0.682036, 1.0)

		// Cloud parameters

		[Header(towelcloud)]
		_noiseMap("cloud noise map", 2D) = "white" {}
			_scale ("Cloud Size (Higher: less repetition)", Float) = 55
			_cloudy ("Cloudiness", Range (0, 1)) = 0.5
			_soft ("Cloud Softness", Range (0.0001, 0.9999)) = 0.4
		//	_rotateY ("rotateY 空の前方の角度", Range (-180, 180)) = 0
		//	_rotateZ ("rotateZ 光の上下角度", Range (-180, 180)) = 60
		//[Header(cloud)]
		//	_farMixRate ("farMixRate 水平線近くで空の色を雲に反映する割合", Range (0, 1)) = 0.6
		//	_farMixLength ("farMixLength 水平線近くで空の色を雲に反映する距離", Range (0, 1)) = 0.3
		//	_cloudFogColor("cloudFogColor 水平線近くで雲に反映する単色", Color) = (1, 1, 1, 0.1)
		//	_cloudFogLength("cloudFogLength 単色のグラデーション幅", Range (0, 1)) = 0.3
		[Header(horizon)]
			[Toggle]_underFade ("underFade 下の方の雲を消す", Float) = 1
			_underFadeStart ("underFadeStart 消し始める位置", Range (-1, 1)) = -0.5
			_underFadeWidth ("underFadeWidth 消すときのグラデーション幅", Range (0.0001, 0.9999)) = 0.2
			//[Toggle]_groundFill ("groundFill 下方向を塗りつぶす", Float) = 0
			//_groundFillColor ("groundFillColor 下方向を塗りつぶす色", Color) = (0.13, 0.11, 0.1, 1)
		[Header(move)]
			_moveRotation ("moveRotation 雲の移動方向", Range (0, 360)) = 0
			_speed_parameter ("speed 雲の速度", Float) = 1
			_shapeSpeed_parameter ("shapeSpeed 雲の変形量", Float) = 1
			_speedOffset ("speedOffset 雲の細かい部分の速度差", Float) = 0.2
			_speedSlide ("speedSlide 雲の細かい部分の横方向への速度", Float) = 0.1
		[Header(rim)]
			_rimForce ("rimForce ふちの光の強さ", Float) = 0.5
			_rimNarrow ("rimNarrow ふちの光の細さ", Float) = 2
		[Header(scattering)]
			[Toggle] _scattering ("scattering 拡散光を使う", Float) = 0
			_scatteringColor ("scatteringColor 拡散光の色", Color) = (1, 1, 1, 1)
			_scatteringForce ("scatteringForce 拡散光の強さ", Range (0, 3)) = 0.8
			_scatteringRange ("scatteringRange 拡散光の影響を受ける範囲", Range (0, 1)) = 0.3
			_scatteringNarrow ("scatteringNarrow 拡散光のふちの細さ", Float) = 1
		[Header(faceWind)]
			_faceWindScale_parameter ("faceWindScale 表面風の大きさ", Float) = 1
			_faceWindForce_parameter ("faceWindForce 表面風の強さ", Float) = 1
			_faceWindMove ("faceWindMove 表面風の移動速度", Float) = 1.3
			_faceWindMoveSlide ("faceWindMoveSlide 表面風の細かい部分の移動速度", Float) = 1.8
		[Header(farWind)]
			_farWindDivision ("farWindDivision 遠方風の分割数", Int) = 35
			_farWindForce_parameter ("farWindForce 遠方風の強さ", Float) = 1
			_farWindMove ("farWindMove 遠方風の移動速度", Float) = 2
			_farWindTopEnd ("farWindTopEnd 遠方風の上の消える位置", Float) = 0.5
			_farWindTopStart ("farWindTopStart 遠方風の上の弱まり始める位置", Float) = 0.3
			_farWindBottomStart ("farWindBottomStart 遠方風の下の弱まり始める位置", Float) = 0.1
			_farWindBottomEnd ("farWindBottomEnd 遠方風の下の消える位置", Float) = -0.1
		[Header(stream)]
			[Toggle] _stream ("stream 気流", Float) = 1
			_streamForce ("streamForce 気流の強さ", Float) = 5
			_streamScale ("streamScale 気流の大きさ", Float) = 5
			_streamMove ("streamMove 気流の移動速度", Float) = 1.5
		[Header(etc)]
			_fbmScaleUnder ("fbmScaleUnder 雲の細かい部分の変形値", Float) = 0.43
			_boost ("boost 雲の光を強める値", Float) = 1.1
			_chine ("chine 雲の尾根のやわらかさ", Float) = 0.5
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

			#include "UnityCG.cginc"
			#include "Definitions.cginc"
			#include "UtilityFunctions.cginc"
			#include "TransmittanceFunctions.cginc"
			#include "ScatteringFunctions.cginc"
			#include "IrradianceFunctions.cginc"
			#include "RenderingFunctions.cginc"
			#include "CloudFunctions.cginc"
			#include "NightSkyFunctions.cginc"

            float units_to_atmosphere_boundary;
            uint tonemap;
            uint gammaCorrection;
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

			float3 colorMultiplier;
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

                float3 p = view_position;
                p /= units_to_atmosphere_boundary;
                p *= (top_radius - bottom_radius);
                p.y += bottom_radius;

				// It seems like calculating the clouds first would be the faster path to take.
				// By calculating the clouds first, we can avoid needing to sample sky radiance
				// twice. Still, sampling sky radiance shouldn't be expensive...

				CloudOutputData cloudData = GetCloudAtmosphere(p, -view_direction, sun_direction, transmittance,
					transmittance_texture, scattering_texture);
				float3 cloudWorldNormal = cloudData.cloudWorldNormal;
				float cloudPower = cloudData.cloudPower;
				float cloudAreaRate = cloudData.cloudAreaRate;
					
				// それぞれのdotから光影響を計算
				float3 invY = float3(1, -1, 1);
				float3 skyVector = float3(1, 0, 0);
				float3 cloudLightDirection = sun_direction; //invY*-reflect(sun_direction, skyVector);
				float normalDot = dot(cloudWorldNormal, cloudLightDirection);
				float normalDotForUv = normalDot * 0.5 + 0.5;
				float viewDotToLightForUv = dot(view_direction, cloudLightDirection) * 0.5 + 0.5;
				float viewDotToSkyForUv = dot(view_direction, skyVector) * 0.5 + 0.5;
				
				// Get the cloud colour from the colour of the atmosphere when it's at
				// maximum density.
				float3 cloudViewDir = float3(view_direction.x, 0, view_direction.z);
				float3 cloudP = float3(0, 
					(top_radius - bottom_radius) / units_to_atmosphere_boundary
					 * view_position.y + bottom_radius, 
					0);
				float3 transmittance_cloud;
				
				float3 cloudColor = GetSkyRadiance(cloudP, cloudViewDir, 0, cloudLightDirection, 
					transmittance_cloud);
				float cloudOcclusion = 1-(normalDotForUv * cloudPower);


				radiance = (cloudPower < 1.0)
					? GetSkyRadiance(p, view_direction, shadow_length, sun_direction, 
					transmittance)
					: cloudColor;

				// If the view ray intersects the Sun, add the Sun radiance.
				// Note that there are two ways of handling the sun colour.
				// When baking reflection probes, the skybox is not told the colour of the sun
				// to avoid doubled sun reflections. However, this can look bad visually, especially
				// when a realtime light is not present in the scene. To avoid this, Unity's regular
				// procedural skybox uses this workaround which clamps the max intensity of the
				// sky's sun. This isn't desirable for all scenarios though.
            	half lightColorIntensity = clamp(length(_LightColor0.xyz), 0.25, 1) ;
				float sunAttenuation = smoothstep(sun_size.y, 1, dot(view_direction, sun_direction));
				if (sunAttenuation > 0)
				{
					radiance += sunAttenuation * transmittance * GetSolarRadiance() //* 1e-4 
						* (_LightColor0.xyz / lightColorIntensity);
				}

				// Todo: Finish re-adding moon.

				float3 sunColorClouds =  transmittance * (_LightColor0.xyz / lightColorIntensity);
				float3 nightCloudCol = 1e-6 * GetSolarRadiance() * _MoonColor;

				// Add rim light and transmission to clouds
				
				// == 境界が光る度合いを用意
					float rimPowerR = cloudAreaRate * _rimNarrow;
					rimPowerR = quadOut(saturate(rimPowerR));
					float rimPower = (1 - rimPowerR) * _rimForce;
					rimPower = saturate(rimPower);
					// 境界の光の色を設定
					float2 rimUv = float2(viewDotToLightForUv, normalDotForUv);
					//float3 rimColor =  transmittance;
					//cloudColor.rgb =  rimColor.rgb * rimPower + cloudColor.rgb;
					float3 rimAddColor = (1-normalDotForUv) * transmittance 
						* cloudPower * _rimForce * rimPower;
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
						cloudColor.rgb += scatteringPower * _scatteringColor 
							* _scatteringForce * sunColorClouds;
						nightCloudCol.rgb += (scatteringPower * _scatteringColor
							* nightCloudCol);
					}

				// Add stars.
				// In real life, stars are always visible, but the atmosphere is too 
				// bright for us to see them. However, dealing with realistic
				// light ranges in Unity (let alone VRchat) is a huge pain. Instead,
				// let's fake it. 
				float atmosLuma = dot(radiance, 1.0/3.0);
				float3 nightSky = getNightSky(view_position, view_direction);

				nightSky *= GetSolarRadiance() * 1e-5 * transmittance;
				nightSky += transmittance;
				nightSky += nightCloudCol * (1-cloudOcclusion);

				radiance += (1-cloudPower) * nightSky / max(1, atmosLuma/2);

				// Finish applying cloud colour. 
				radiance = lerp(radiance, cloudColor, saturate(cloudPower));
				
                radiance = (radiance/white_point)*exposure;
				radiance += max(0, normalDotForUv * sunColorClouds) * saturate(cloudPower) + rimAddColor;

				radiance *= colorMultiplier.rgb;

				return float4(radiance, 1);
			}
            ENDCG
        }
    }
}
