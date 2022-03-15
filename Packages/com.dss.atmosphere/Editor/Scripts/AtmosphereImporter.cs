using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using BrunetonsImprovedAtmosphere;
using UnityEngine;
using UnityEditor;
using Object = UnityEngine.Object;

#if UNITY_2020_2_OR_NEWER
using UnityEditor.AssetImporters;
#else
using UnityEditor.Experimental.AssetImporters;
#endif

// Based on the original editor window script.
// Allows the creation of "Atmosphere" assets which can be easily regenerated.

namespace DSS.Atmosphere
{
    [CanEditMultipleObjects]
    [ScriptedImporter(k_VersionNumber, AtmosphereImporter.kFileExtension)]
    public class AtmosphereImporter : ScriptedImporter
    {
    	// Material parameters.
    	[Header("Material Parameters")]
    	public float UnitsToAtmosphereBoundary = 6000.0f;
		public bool Tonemap = false; // Not needed in HDR?
		public bool GammaCorrection = false;
		public bool ClampViewVector = true; 
		public Color ColorMultiplier = new Color(1.0f, 1.0f, 1.0f, 1.0f);
        // Simulation parameters.
    	[Header("Simulation Parameters")]
        public bool UseConstantSolarSpectrum = true;
        public bool UseOzone = true;
        private bool UseCombinedTextures = false; // Seems to not be supported
        public bool UseHalfPrecision = true;
        public bool DoWhiteBalance = true;
        public LUMINANCE UseLuminance = LUMINANCE.PRECOMPUTED;
        public float Exposure = 10.0f;

        // Load from Resources.
        private ComputeShader _precomputation;
        private Material _material;

        // Private variables.
        private Model m_model;

        private Texture2D m_transmittanceTexture;
        private Texture3D m_scatteringTexture;
        private Texture3D m_singleMieScatteringTexture;
        private Texture2D m_irradianceTexture;

        private bool _showErrorMessage = false;
        private string _errorMessage = "";

        // Private constants.
        private const float kSunAngularRadius = 0.00935f / 2.0f;
        private const float kBottomRadius = 6360000.0f;
        private const float kLengthUnitInMeters = 1000.0f;
#if UNITY_2020_1_OR_NEWER
        const int k_VersionNumber = 202010;
#else
        const int k_VersionNumber = 201940;
#endif

        /// The file extension used for Atmosphere assets without leading dot.
        public const string kFileExtension = "atmosphere";

        public override void OnImportAsset(AssetImportContext ctx)
        {
        	// We could mark the resources as dependancies, but they aren't.
#if !UNITY_2020_1_OR_NEWER
            // This value is not really used in this importer,
            // but getting the build target here will add a dependency to the current active buildtarget.
            // Because DependsOnArtifact does not exist in 2019.4, adding this dependency on top of the DependsOnSourceAsset
            // will force a re-import when the target platform changes in case it would have impacted anything this importer depends on.
            var buildTarget = ctx.selectedBuildTarget;
#endif
            if (SystemInfo.supportsComputeShaders) {
            	// The original script creates the texture files here - this shouldn't be necessary
            	// because we can add them to the asset.
            	LoadResources();
            	Verify();
                Precompute();
                SaveTextures(ctx);
            }
            UpdateMaterial();
        }

        private void LoadResources()
        {
            _precomputation = Resources.Load("Precomputation") as ComputeShader;
            if (_precomputation == null) {
                throw new ArgumentException("Unable to load Precomputation.compute from Resources.");
            }
            Shader s = Resources.Load("Atmosphere") as Shader;
            if (s == null) {
                throw new ArgumentException("Unable to load Atmosphere.shader from Resources.");
            }
            _material = new Material(s);
        }

        private void Verify()
        {
            if (_precomputation == null) {
                throw new ArgumentException("The precomputation compute shader must be assigned.");
            }

            if (_material == null) {
                throw new ArgumentException("The material must be assigned.");
            }

            if (_material.shader != Shader.Find("DSS/AtmosphericSkybox")) {
                throw new ArgumentException("The material must use the shader: \"DSS/AtmosphericSkybox\".");
            }
        }

        private void Precompute()
        {
            // Values from "Reference Solar Spectral Irradiance: ASTM G-173", ETR column
            // (see http://rredc.nrel.gov/solar/spectra/am1.5/ASTMG173/ASTMG173.html),
            // summed and averaged in each bin (e.g. the value for 360nm is the average
            // of the ASTM G-173 values for all wavelengths between 360 and 370nm).
            // Values in W.m^-2.
            int kLambdaMin = 360;
            int kLambdaMax = 830;

            double[] kSolarIrradiance = new double[]
            {
                1.11776, 1.14259, 1.01249, 1.14716, 1.72765, 1.73054, 1.6887, 1.61253,
                1.91198, 2.03474, 2.02042, 2.02212, 1.93377, 1.95809, 1.91686, 1.8298,
                1.8685, 1.8931, 1.85149, 1.8504, 1.8341, 1.8345, 1.8147, 1.78158, 1.7533,
                1.6965, 1.68194, 1.64654, 1.6048, 1.52143, 1.55622, 1.5113, 1.474, 1.4482,
                1.41018, 1.36775, 1.34188, 1.31429, 1.28303, 1.26758, 1.2367, 1.2082,
                1.18737, 1.14683, 1.12362, 1.1058, 1.07124, 1.04992
            };

            // Values from http://www.iup.uni-bremen.de/gruppen/molspec/databases/
            // referencespectra/o3spectra2011/index.html for 233K, summed and averaged in
            // each bin (e.g. the value for 360nm is the average of the original values
            // for all wavelengths between 360 and 370nm). Values in m^2.
            double[] kOzoneCrossSection = new double[]
            {
                1.18e-27, 2.182e-28, 2.818e-28, 6.636e-28, 1.527e-27, 2.763e-27, 5.52e-27,
                8.451e-27, 1.582e-26, 2.316e-26, 3.669e-26, 4.924e-26, 7.752e-26, 9.016e-26,
                1.48e-25, 1.602e-25, 2.139e-25, 2.755e-25, 3.091e-25, 3.5e-25, 4.266e-25,
                4.672e-25, 4.398e-25, 4.701e-25, 5.019e-25, 4.305e-25, 3.74e-25, 3.215e-25,
                2.662e-25, 2.238e-25, 1.852e-25, 1.473e-25, 1.209e-25, 9.423e-26, 7.455e-26,
                6.566e-26, 5.105e-26, 4.15e-26, 4.228e-26, 3.237e-26, 2.451e-26, 2.801e-26,
                2.534e-26, 1.624e-26, 1.465e-26, 2.078e-26, 1.383e-26, 7.105e-27
            };

            // From https://en.wikipedia.org/wiki/Dobson_unit, in molecules.m^-2.
            double kDobsonUnit = 2.687e20;
            // Maximum number density of ozone molecules, in m^-3 (computed so at to get
            // 300 Dobson units of ozone - for this we divide 300 DU by the integral of
            // the ozone density profile defined below, which is equal to 15km).
            double kMaxOzoneNumberDensity = 300.0 * kDobsonUnit / 15000.0;
            // Wavelength independent solar irradiance "spectrum" (not physically
            // realistic, but was used in the original implementation).
            double kConstantSolarIrradiance = 1.5;
            double kTopRadius = 6420000.0;
            double kRayleigh = 1.24062e-6;
            double kRayleighScaleHeight = 8000.0;
            double kMieScaleHeight = 1200.0;
            double kMieAngstromAlpha = 0.0;
            double kMieAngstromBeta = 5.328e-3;
            double kMieSingleScatteringAlbedo = 0.9;
            double kMiePhaseFunctionG = 0.8;
            double kGroundAlbedo = 0.1;
            double max_sun_zenith_angle = (UseHalfPrecision ? 102.0 : 120.0) / 180.0 * Mathf.PI;

            DensityProfileLayer rayleigh_layer = new DensityProfileLayer("rayleigh", 0.0, 1.0, -1.0 / kRayleighScaleHeight, 0.0, 0.0);
            DensityProfileLayer mie_layer = new DensityProfileLayer("mie", 0.0, 1.0, -1.0 / kMieScaleHeight, 0.0, 0.0);

            // Density profile increasing linearly from 0 to 1 between 10 and 25km, and
            // decreasing linearly from 1 to 0 between 25 and 40km. This is an approximate
            // profile from http://www.kln.ac.lk/science/Chemistry/Teaching_Resources/
            // Documents/Introduction%20to%20atmospheric%20chemistry.pdf (page 10).
            List<DensityProfileLayer> ozone_density = new List<DensityProfileLayer>();
            ozone_density.Add(new DensityProfileLayer("absorption0", 25000.0, 0.0, 0.0, 1.0 / 15000.0, -2.0 / 3.0));
            ozone_density.Add(new DensityProfileLayer("absorption1", 0.0, 0.0, 0.0, -1.0 / 15000.0, 8.0 / 3.0));

            List<double> wavelengths = new List<double>();
            List<double> solar_irradiance = new List<double>();
            List<double> rayleigh_scattering = new List<double>();
            List<double> mie_scattering = new List<double>();
            List<double> mie_extinction = new List<double>();
            List<double> absorption_extinction = new List<double>();
            List<double> ground_albedo = new List<double>();

            for (int l = kLambdaMin; l <= kLambdaMax; l += 10)
            {
                double lambda = l * 1e-3;  // micro-meters
                double mie = kMieAngstromBeta / kMieScaleHeight * Math.Pow(lambda, -kMieAngstromAlpha);

                wavelengths.Add(l);

                if (UseConstantSolarSpectrum)
                    solar_irradiance.Add(kConstantSolarIrradiance);
                else
                    solar_irradiance.Add(kSolarIrradiance[(l - kLambdaMin) / 10]);

                rayleigh_scattering.Add(kRayleigh * Math.Pow(lambda, -4));
                mie_scattering.Add(mie * kMieSingleScatteringAlbedo);
                mie_extinction.Add(mie);
                absorption_extinction.Add(UseOzone ? kMaxOzoneNumberDensity * kOzoneCrossSection[(l - kLambdaMin) / 10] : 0.0);
                ground_albedo.Add(kGroundAlbedo);
            }

            m_model = new Model();

            m_model.HalfPrecision = UseHalfPrecision;
            m_model.CombineScatteringTextures = UseCombinedTextures;
            m_model.UseLuminance = UseLuminance;
            m_model.Wavelengths = wavelengths;
            m_model.SolarIrradiance = solar_irradiance;
            m_model.SunAngularRadius = kSunAngularRadius;
            m_model.BottomRadius = kBottomRadius;
            m_model.TopRadius = kTopRadius;
            m_model.RayleighDensity = rayleigh_layer;
            m_model.RayleighScattering = rayleigh_scattering;
            m_model.MieDensity = mie_layer;
            m_model.MieScattering = mie_scattering;
            m_model.MieExtinction = mie_extinction;
            m_model.MiePhaseFunctionG = kMiePhaseFunctionG;
            m_model.AbsorptionDensity = ozone_density;
            m_model.AbsorptionExtinction = absorption_extinction;
            m_model.GroundAlbedo = ground_albedo;
            m_model.MaxSunZenithAngle = max_sun_zenith_angle;
            m_model.LengthUnitInMeters = kLengthUnitInMeters;

            int numScatteringOrders = 4;
            m_model.Init(_precomputation, numScatteringOrders);

            m_model.BindToMaterial(_material);

            // Get the textures from the model and save them to this instance.
            RenderTexture transmittance, scattering, singleMieScattering, irradiance;
            m_model.GetTextures(out transmittance, out scattering, out singleMieScattering, out irradiance);
            m_transmittanceTexture = transmittance.ToTexture2D();
            m_scatteringTexture = scattering.ToTexture3D();
            m_singleMieScatteringTexture = singleMieScattering.ToTexture3D();
            m_irradianceTexture = irradiance.ToTexture2D();

            // Release the temporary render textures.
            m_model.Release();
        }

        private void SaveTextures(AssetImportContext ctx)
        {
            ctx.AddObjectToAsset("main material", _material);
        	ctx.SetMainObject(_material);
        	// Add names to textures for UX.
        	m_transmittanceTexture.name = "Transmittance LUT";
			m_scatteringTexture.name = "Scattering LUT";
			m_singleMieScatteringTexture.name = "Mie Scattering LUT";
			m_irradianceTexture.name = "Irradiance LUT";
            ctx.AddObjectToAsset("transmittance texture", m_transmittanceTexture);
            ctx.AddObjectToAsset("scattering texture", m_scatteringTexture);
            ctx.AddObjectToAsset("singleMieScattering texture", m_singleMieScatteringTexture);
            ctx.AddObjectToAsset("irradiance texture", m_irradianceTexture);
        }

        private void UpdateMaterial()
        {
        	_material.SetFloat("units_to_atmosphere_boundary", UnitsToAtmosphereBoundary);
        	_material.SetFloat("tonemap", Tonemap ? 1 : 0);
        	_material.SetFloat("gammaCorrection", GammaCorrection ? 1 : 0);
        	_material.SetFloat("clampViewVector", ClampViewVector ? 1 : 0);
        	_material.SetVector("colorMultiplier", ColorMultiplier);

            _material.SetFloat("exposure", UseLuminance != LUMINANCE.NONE ? Exposure * 1e-5f : Exposure);
            _material.SetVector("earth_center", new Vector3(0.0f, -kBottomRadius / kLengthUnitInMeters, 0.0f));
            _material.SetVector("sun_size", new Vector2(Mathf.Tan(kSunAngularRadius), Mathf.Cos(kSunAngularRadius)));

            _material.SetTexture("transmittance_texture", m_transmittanceTexture);
            _material.SetTexture("scattering_texture", m_scatteringTexture);
            _material.SetTexture("single_mie_scattering_texture", m_singleMieScatteringTexture);
            _material.SetTexture("irradiance_texture", m_irradianceTexture);

            double white_point_r = 1.0;
            double white_point_g = 1.0;
            double white_point_b = 1.0;

            if (DoWhiteBalance)
            {
                if (m_model != null)
                {
                    m_model.ConvertSpectrumToLinearSrgb(out white_point_r, out white_point_g, out white_point_b);
                }

                double white_point = (white_point_r + white_point_g + white_point_b) / 3.0;
                white_point_r /= white_point;
                white_point_g /= white_point;
                white_point_b /= white_point;
            }

            _material.SetVector("white_point", new Vector3((float)white_point_r, (float)white_point_g, (float)white_point_b));
        }

        [MenuItem("Assets/Create/Atmosphere Generator", priority = 310)]
        static void CreateAtmosphereMenuItem()
        {
            var kAtmosphereAssetContent = "This file represents a Atmosphere asset for Unity.\nYou need the 'Atmosphere' package to properly import this file in Unity.";
            // https://forum.unity.com/threads/how-to-implement-create-new-asset.759662/
            string directoryPath = "Assets";
            foreach (Object obj in Selection.GetFiltered(typeof(Object), SelectionMode.Assets))
            {
                directoryPath = AssetDatabase.GetAssetPath(obj);
                if (!string.IsNullOrEmpty(directoryPath) && File.Exists(directoryPath))
                {
                    directoryPath = Path.GetDirectoryName(directoryPath);
                    break;
                }
            }
            directoryPath = directoryPath.Replace("\\", "/");
            if (directoryPath.Length > 0 && directoryPath[directoryPath.Length - 1] != '/')
                directoryPath += "/";
            if (string.IsNullOrEmpty(directoryPath))
                directoryPath = "Assets/";

            var fileName = string.Format("New Atmosphere.{0}", kFileExtension);
            directoryPath = AssetDatabase.GenerateUniqueAssetPath(directoryPath + fileName);
            ProjectWindowUtil.CreateAssetWithContent(directoryPath, kAtmosphereAssetContent);
        }
    }

    [CanEditMultipleObjects]
	[CustomEditor(typeof(AtmosphereImporter))]
	public class AtmosphereImporterEditor: ScriptedImporterEditor
	{
	    public override void OnInspectorGUI()
	    {
            // Verify that compute shaders are supported.
            if (!SystemInfo.supportsComputeShaders) {
                EditorGUILayout.HelpBox("This tool requires a GPU that supports compute shaders. Simulation parameters can not be updated.", MessageType.Error);
            }

	        base.OnInspectorGUI();
	        // base.ApplyRevertGUI();
	    }
	}
}
