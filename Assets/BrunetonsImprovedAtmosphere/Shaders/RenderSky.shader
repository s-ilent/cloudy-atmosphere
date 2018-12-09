Shader "Hidden/RenderSky"
{
	/**
	* Copyright (c) 2017 Eric Bruneton
	* All rights reserved.
	*
	* Redistribution and use in source and binary forms, with or without
	* modification, are permitted provided that the following conditions
	* are met:
	* 1. Redistributions of source code must retain the above copyright
	*    notice, this list of conditions and the following disclaimer.
	* 2. Redistributions in binary form must reproduce the above copyright
	*    notice, this list of conditions and the following disclaimer in the
	*    documentation and/or other materials provided with the distribution.
	* 3. Neither the name of the copyright holders nor the names of its
	*    contributors may be used to endorse or promote products derived from
	*    this software without specific prior written permission.
	*
	* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	* ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	* LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	* INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	* THE POSSIBILITY OF SUCH DAMAGE.
	*/
	Properties
	{
		units_to_atmosphere_top ("Units to Atmosphere Boundary", Int) = 60
		lateral_scale_x ("Lateral Scale X", Int) = 1
		lateral_scale_z ("Lateral Scale Z", Int) = 1

		[MaterialToggle] clamp_horizon ("Clamp Horizon View", Int) = 0 
		
		[HideInInspector] transmittance_texture ("Transmittance", 2D) = "white" {}
		[HideInInspector] irradiance_texture ("Irradiance", 2D) = "white" {}
		[HideInInspector] scattering_texture ("Scattering", 3D) = "white" {}
		[HideInInspector] single_mie_scattering_texture ("Mie", 3D) = "white" {}

		[HideInInspector] exposure ("exposure", Float) = 0
		[HideInInspector] white_point ("white_point", Vector) = (0,0,0)
		[HideInInspector] earth_center ("earth_center", Vector) = (0,0,0)
		[HideInInspector] sun_size ("sun_size", Vector) = (0,0,0)

		[HideInInspector] TRANSMITTANCE_TEXTURE_WIDTH ("TRANSMITTANCE_TEXTURE_WIDTH", Int) = 0
		[HideInInspector] TRANSMITTANCE_TEXTURE_HEIGH ("TRANSMITTANCE_TEXTURE_HEIGH", Int) = 0
		[HideInInspector] SCATTERING_TEXTURE_R_SIZE ("SCATTERING_TEXTURE_R_SIZE", Int) = 0
		[HideInInspector] SCATTERING_TEXTURE_MU_SIZE ("SCATTERING_TEXTURE_MU_SIZE", Int) = 0
		[HideInInspector] SCATTERING_TEXTURE_MU_S_SIZE ("SCATTERING_TEXTURE_MU_S_SIZE", Int) = 0
		[HideInInspector] SCATTERING_TEXTURE_NU_SIZE ("SCATTERING_TEXTURE_NU_SIZE", Int) = 0
		[HideInInspector] SCATTERING_TEXTURE_WIDTH ("SCATTERING_TEXTURE_WIDTH", Int) = 0
		[HideInInspector] SCATTERING_TEXTURE_HEIGHT ("SCATTERING_TEXTURE_HEIGHT", Int) = 0
		[HideInInspector] SCATTERING_TEXTURE_DEPTH ("SCATTERING_TEXTURE_DEPTH", Int) = 0
		[HideInInspector] IRRADIANCE_TEXTURE_WIDTH ("IRRADIANCE_TEXTURE_WIDTH", Int) = 0
		[HideInInspector] IRRADIANCE_TEXTURE_HEIGHT ("IRRADIANCE_TEXTURE_HEIGHT", Int) = 0
	 	[HideInInspector] sun_angular_radius ("sun_angular_radius", Float) = 0
		[HideInInspector] bottom_radius ("bottom_radius", Float) = 0
		[HideInInspector] top_radius ("top_radius", Float) = 0
		[HideInInspector] mie_phase_function_g ("mie_phase_function_g", Float) = 0
		[HideInInspector] mu_s_min ("mu_s_min", Float) = 0

		[HideInInspector] SKY_SPECTRAL_RADIANCE_TO_LUMINANCE ("SKY_SPECTRAL_RADIANCE_TO_LUMINANCE", Vector) = (0, 0, 0)
		[HideInInspector] SUN_SPECTRAL_RADIANCE_TO_LUMINANCE ("SUN_SPECTRAL_RADIANCE_TO_LUMINANCE", Vector) = (0, 0, 0)
		[HideInInspector] solar_irradiance ("solar_irradiance", Vector) = (0, 0, 0)
		[HideInInspector] rayleigh_scattering ("rayleigh_scattering", Vector) = (0, 0, 0)
		[HideInInspector] mie_scattering ("mie_scattering", Vector) = (0, 0, 0)
	}
	SubShader
	{
		Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" "IsEmissive" = "true" }

    	Cull Off ZWrite Off
		
		Pass
		{

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile __ RADIANCE_API_ENABLED
			#pragma multi_compile __ COMBINED_SCATTERING_TEXTURES
			
			#include "UnityCG.cginc"
			#include "Definitions.cginc"
			#include "UtilityFunctions.cginc"
			#include "TransmittanceFunctions.cginc"
			#include "ScatteringFunctions.cginc"
			#include "IrradianceFunctions.cginc"
			#include "RenderingFunctions.cginc"

			float units_to_atmosphere_top;
			float lateral_scale_x;
			float lateral_scale_z;
			int clamp_horizon;

			float exposure;
			float3 white_point;
			float3 earth_center;
			float2 sun_size;

			sampler2D transmittance_texture;
			sampler2D irradiance_texture;
			sampler3D scattering_texture;
			sampler3D single_mie_scattering_texture;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 uvw : TEXCOORD0;
			};

			struct v2f
			{
				float3 view_ray : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
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

			RadianceSpectrum GetSkyRadiance(
				Position camera, Direction view_ray, Length shadow_length,
				Direction sun_direction, out DimensionlessSpectrum transmittance) 
			{
				return GetSkyRadiance(transmittance_texture,
					scattering_texture, single_mie_scattering_texture,
					camera, view_ray, shadow_length, sun_direction, transmittance);
			}
#else
			Luminance3 GetSolarRadiance()
			{
				return solar_irradiance /
					(PI * sun_angular_radius * sun_angular_radius) *
					SUN_SPECTRAL_RADIANCE_TO_LUMINANCE;
			}

			Luminance3 GetSkyRadiance(
				Position camera, Direction view_ray, Length shadow_length,
				Direction sun_direction, out DimensionlessSpectrum transmittance) 
			{
				return GetSkyRadiance(transmittance_texture,
					scattering_texture, single_mie_scattering_texture,
					camera, view_ray, shadow_length, sun_direction, transmittance) *
					SKY_SPECTRAL_RADIANCE_TO_LUMINANCE;
			}
#endif
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 camera = _WorldSpaceCameraPos;
				float3 view_direction = normalize(i.view_ray);
				float3 sun_direction = _WorldSpaceLightPos0.xyz;

				if (clamp_horizon == 1) {
					view_direction.y = saturate(view_direction.y);
				}

				float shadow_length = 0;
				float3 transmittance;

				float3 pos;

				pos.x = lateral_scale_x * (camera.x - earth_center.x);
				pos.y = (top_radius - bottom_radius) / units_to_atmosphere_top * camera.y + bottom_radius;
				pos.z = lateral_scale_z * (camera.z - earth_center.z);

				float3 radiance = GetSkyRadiance(pos, view_direction, shadow_length, sun_direction, transmittance);

				// If the view ray intersects the Sun, add the Sun radiance.
				if (dot(view_direction, sun_direction) > sun_size.y) 
				{
					radiance = radiance + transmittance * GetSolarRadiance() * 1e-4;
				}

				radiance = pow(float3(1,1,1) - exp(-radiance / white_point * exposure), 1.0 / 2.2);

				radiance = saturate(radiance);

				return float4(radiance, 1);
			}

			ENDCG
		}
	}
}
