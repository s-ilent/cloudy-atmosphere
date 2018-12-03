using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

namespace BrunetonsImprovedAtmosphere {

public static class TextureUtilities {

    public static Texture3D blackTexture3D() {
        Texture3D tmp = new Texture3D(1,1,1, TextureFormat.RGBAFloat, false);

        Color32[] pixels = tmp.GetPixels32();
        for (int i = 0; i < pixels.Length; i++) {
            pixels[i] = new Color32(0, 0, 0, 255);
        }
        tmp.SetPixels32(pixels);
        tmp.Apply();

        return tmp;
    }

    public static Texture2D ToTexture2D (this RenderTexture rt) {
        if (rt.dimension != TextureDimension.Tex2D) {
            throw new System.InvalidCastException("expected a two-dimensional render texture");
        }

        TextureFormat tmp_f = (rt.format == RenderTextureFormat.ARGBFloat) ? TextureFormat.RGBAFloat : TextureFormat.RGBAHalf;

        Texture2D tmp = new Texture2D(rt.width, rt.height, tmp_f, rt.useMipMap);     
        tmp.filterMode = rt.filterMode;
        tmp.anisoLevel = rt.anisoLevel;
        tmp.wrapMode = rt.wrapMode;
        
        Graphics.CopyTexture(rt, tmp);

        return tmp;
    }

    public static Texture3D ToTexture3D (this RenderTexture rt) {
       if (rt.dimension != TextureDimension.Tex3D) {
            throw new System.InvalidCastException("expected a three-dimensional render texture");
        }

        TextureFormat tmp_f = (rt.format == RenderTextureFormat.ARGBFloat) ? TextureFormat.RGBAFloat : TextureFormat.RGBAHalf;

        Texture3D tmp = new Texture3D(rt.width, rt.height, rt.volumeDepth, tmp_f, rt.useMipMap);     
        tmp.filterMode = rt.filterMode;
        tmp.anisoLevel = rt.anisoLevel;
        tmp.wrapMode = rt.wrapMode;
        
        Graphics.CopyTexture(rt, tmp);

        return tmp;
    }

}  // TextureUtilities

}  // namespace BrunetonsImprovedAtmosphere
