# Cloudy Atmosphere

A physically-based atmospheric skybox shader for Unity, with less physically based extensions for visual flair. Based on work by [Daniel Shervheim](https://github.com/danielshervheim/unity-bruneton-atmosphere), [Eric Bruneton](https://github.com/ebruneton/precomputed_atmospheric_scattering) and [Scrawk](https://github.com/Scrawk/Brunetons-Improved-Atmospheric-Scattering), as well as [towelfunnel](https://gitlab.com/towelfunnelvrc/towelcloud).

## How to Install

This repo contains a Unity package. Place the `com.dss.atmosphere` folder from the Packages directory into your Unity project.

## How to Use

Please see the [readme](Packages/com.dss.atmosphere/README.md) in the package directory for usage information.

## Results

![midday](https://i.imgur.com/ewiTBgX.png)
![sunset](https://i.imgur.com/FI0mD97.png)
![twilight](https://i.imgur.com/FRgBzV9.png)

## Credit

This is an extension of danielshervheim's [extension](https://github.com/danielshervheim/unity-bruneton-atmosphere) of scrawk's [implementation](https://github.com/Scrawk/Brunetons-Improved-Atmospheric-Scattering) of ebruneton's [improved atmospheric scattering](https://github.com/ebruneton/precomputed_atmospheric_scattering) paper.

I added towelfunnel's [clouds](https://gitlab.com/towelfunnelvrc/towelcloud) as well as stars. I originally made this for my own personal use, as it's just a bunch of other shaders hacked together, but lots of people were interested in it, so I polished it up and made it a bit easier to use. 