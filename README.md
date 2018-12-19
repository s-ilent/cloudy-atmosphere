# Bruneton's Improved Atmospheric Scattering for Unity

This is an extension of scrawk's [implementation](https://github.com/Scrawk/Brunetons-Improved-Atmospheric-Scattering) of ebruneton's [improved atmospheric scattering](https://github.com/ebruneton/precomputed_atmospheric_scattering) paper.

Scrawk's Unity port, while excellent, was restricted in many ways due to various hardcoded parameters. As he himself noted:

> The demo uses a image effect shader as a example of how to use the scattering. The sphere rendered and its light shafts are hard coded into the shader as its just a example. Some work would be needed to convert this into a practical implementation

This is my attempt at a practical implementation.

## Goals
- To modify the existing codebase as little as possible.
- To enable previewing of the atmosphere in the editor.
- To remove the hardcoded sphere, and image-effect rendering assumptions.
- To enable better control over when / how the scattering textures get precomputed and saved.

## What I changed
- Modified `Model.cs` to serialize the generated scattering RenderTexture objects as Texture2D/Texture3D assets.
- Rewrote `RenderSky.shader` to integrate with the Unity skybox system, and removed the hardcoded elements.
- Wrote a custom GUI for `Demo.cs` to allow better control over precomputation.

## How to setup

### 1. Lighting Settings

##### Required

1. Select "Window > Lighting > Settings" from menu bar. A **Lighting** window will appear somewhere on your screen.
2. Locate the **Enviroment** heading in the Lighting window.
3. Populate the **Skybox Material** slot with the material located in the asset browser under "BrunetonsImprovedAtmosphere > Materials > RenderSky.mat".
4. Populate the **Sun Source** slot with the main directional light in your scene (add one first, if you have not already).

##### For best results

5. Change the **Source** dropdown under **Enviroment Lighting** to "Skybox".
6. Change the **Source** dropdown under **Enviroment Reflections** to "Skybox"
7. Verify that **Realtime Global Illumination** is checled "On".
8. Verify that **Baked Global Illumination** is checked "Off".

### 2. Scene

1. Create an empty game object in the scene hierarchy. Name it something descriptive, like "AtmosphereManager".
2. Select your new game object to open its inspector window. Click the **Add Component** button and search for "Demo". Alternatively, you can drag the "Demo script" located at "BrunetonsImprovedAtmosphere > Scripts > Demo.cs" directly onto your game object.
3. Populate the **Compute** slot of the Demo inspector with the shader located at "BrunetonsImprovedAtmosphere > Shaders > Precomputation.compute".
4. Populate the **Material** slot of the Demo inspector with the material located at "BrunetonsImprovedAtmosphere > Materials > RenderSky.mat".
5. Adjust the settings to your liking, and click the **Precompute** button.

### 3. Material Properties

In addition to the precomputation properties in the `Demo` inspector, there are a few a more parameters to configure in the **RenderSky.mat** material itself.

Navigate to "BrunetonsImprovedAtmosphere > Materials > RenderSky.mat" to open the material's inspector. There are 4 parameters to change.

1. **Units to Atmosphere Boundary**: the distance (in unity units - i.e. meters) from (0,0,0) to the top of the atmosphere. The default value is "60", but a more accurate value would be "50000" (50km).
2. **Lateral Scale X**: By default, the planet is centered laterally around the point (0,0). This parameter adjusts the offset. The default value is "1".
3. **Lateral Scale Z**: By default, the planet is centered laterally around the point (0,0). This parameter adjusts the offset. The default value is "1".
4. **Clamp Horizon View**: By default, the atmosphere renders the ground as well as the sky. You should leave this off unless you expeirience unwanted reflection and lighting artefacts.

## Requirements

This project requires a graphics card that supports the following Unity features:
- Compute Shader
- Texture3D
- RenderTexture

This project was tested on an AMD Ryzen 5 / Nvidia GTX 1060 based workstation running Unity 2017.4.12f1.

## Download

Download the .unitypackage from my [Google Drive](https://drive.google.com/file/d/1RW2GX8HSPGVgexnSG5S_qv5g8ndycFrs/view?usp=sharing).

## Results

![midday](https://i.imgur.com/ewiTBgX.png)
![sunset](https://i.imgur.com/FI0mD97.png)
![twilight](https://i.imgur.com/FRgBzV9.png)