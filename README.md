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
- Added a `GetTextures()` method to `Model.cs`.
- Added an `Atmosphere.cs` ScriptableObject to automatically generate the required material and textures.
- Added an `Atmosphere.shader` skybox shader to use the generated textures.

## Requirements

This project requires a graphics card that supports the following Unity features:
- Compute Shader
- Texture3D
- RenderTexture

This project was tested on an AMD Ryzen 5 / Nvidia GTX 1060 based workstation running Unity 2017.4.12f1.

## Results

![midday](https://i.imgur.com/ewiTBgX.png)
![sunset](https://i.imgur.com/FI0mD97.png)
![twilight](https://i.imgur.com/FRgBzV9.png)

## How to setup

#### Generating the atmosphere

1. Right-click in your asset browser and select "New > Atmosphere".
2. Select the newly created Atmosphere asset.
3. Click on the "Precomputation" slot, and drag in the `Precomputation.compute` file.
4. Press Compute.

#### Using it as a skybox

1. Select "Window > Lighting > Settings" from the menu bar.
2. Locate the "Environment" heading in the lighting window.
3. Click the arrow on the Atmosphere asset, and drag the "skyboxMaterial" sub-asset into the "Skybox Material" slot under the environment heading.
4. Drag your scene's main directional light into the "Sun Source" slot.