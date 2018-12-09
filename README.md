# Bruneton's Atmospheric Scattering for Unity

This is an extension of github user [scrawk](https://github.com/Scrawk/Brunetons-Improved-Atmospheric-Scattering)'s implementation of Eric Bruneton's [atmospheric scattering](https://github.com/ebruneton/precomputed_atmospheric_scattering) for Unity.

The original implementation had many hard-coded aspects, and did not work in the editor or play nicely with Unity's skybox system.

## What I changed

- Wrote a GUI for `Demo.cs` component to allow more granularity over when the precomputation happens.
- Modified `Model.cs` to serialize generated scattering RenderTexture' as Texture2D/3D assets, allowing for in-editor skybox previewing.
- Rewrote `RenderSky.shader` to remove the hardcoded sphere, and integrate into Unity's skybox system.

## How to use

### Setting up the skybox

- Open the Lighting settings window
- Drag your "sun" directionalLight into the "Sun Source" slot.
- Drag the RenderSky material from the assets browser into the "Skybox Material" slot.

### Setting up the manager

- Create an empty gameObject in your scene heirarchy.
- Add a "Demo" component to it.
- Set the parameters for the precomputation to your liking.
- Press the "Precompute" button.

## Download .unityPackage

[Download the .unityPackage from my Google Drive](https://drive.google.com/file/d/1RW2GX8HSPGVgexnSG5S_qv5g8ndycFrs/view?usp=sharing).

*(Note that this package requires a graphics card that supports compute shaders and 3D textures).*

![AtmosphericScatter0](https://static.wixstatic.com/media/1e04d5_d954a2a7602c4522b7d039c6e20dab31~mv2.jpg/v1/fill/w_550,h_550,al_c,q_80,usm_0.66_1.00_0.01/1e04d5_d954a2a7602c4522b7d039c6e20dab31~mv2.jpg)

![AtmosphericScatter1](https://static.wixstatic.com/media/1e04d5_55f45d4bed6f46f88a7943ea21c1fedf~mv2.jpg/v1/fill/w_550,h_550,al_c,q_80,usm_0.66_1.00_0.01/1e04d5_55f45d4bed6f46f88a7943ea21c1fedf~mv2.jpg)

![AtmosphericScatter2](https://static.wixstatic.com/media/1e04d5_41d46d0d10bb4615ab3c20fc78c41d78~mv2.jpg/v1/fill/w_550,h_550,al_c,q_80,usm_0.66_1.00_0.01/1e04d5_41d46d0d10bb4615ab3c20fc78c41d78~mv2.jpg)

![AtmosphericScatter3](https://static.wixstatic.com/media/1e04d5_a55dd5ff3b8b4dceaf90d08d8c070016~mv2.jpg/v1/fill/w_550,h_550,al_c,q_80,usm_0.66_1.00_0.01/1e04d5_a55dd5ff3b8b4dceaf90d08d8c070016~mv2.jpg)

![AtmosphericScatter4](https://static.wixstatic.com/media/1e04d5_9929cc45239145fea0520febf8839284~mv2.jpg/v1/fill/w_550,h_550,al_c,q_80,usm_0.66_1.00_0.01/1e04d5_9929cc45239145fea0520febf8839284~mv2.jpg)
