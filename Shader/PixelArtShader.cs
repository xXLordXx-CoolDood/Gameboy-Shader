using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PixelArtShader : MonoBehaviour {
    public Shader ditherShader;

    public bool DEBUG_SETTINGS = false;

    [Range(0.0f, 1.0f)]
    public float spread = 0.5f;
    [Range(0, 2)]
    public int bayerLevel = 2;
    [Range(2, 255)]
    public int ditherColorCount = 2;

    //4-Tone Parameters
    [Range(0, 1)]
    public int palettize;
    [Range(0, 10)]
    public float brightness;
    public Four_Tone_Palette palette;

    public int resolutionHeight, resolutionWidth;

    public bool pointFilterDown = false;

    private Material shaderMat;
    
    void OnEnable() {
        shaderMat = new Material(ditherShader);
        shaderMat.hideFlags = HideFlags.HideAndDontSave;
        //Set variables for our shaders
        shaderMat.SetColor("_ToneVeryLight", palette.veryLightTone);
        shaderMat.SetColor("_ToneLight", palette.lightTone);
        shaderMat.SetColor("_ToneDark", palette.darkTone);
        shaderMat.SetColor("_ToneVeryDark", palette.veryDarkTone);
        if (palettize == 0) { shaderMat.SetFloat("_Spread", spread); }
        else { shaderMat.SetFloat("_Spread", palette.ditherSpread); }
        shaderMat.SetFloat("_BrightnessMultiplier", brightness);
        shaderMat.SetInt("_DitherColorCount", ditherColorCount);
        shaderMat.SetInt("_BayerLevel", bayerLevel);
        shaderMat.SetInt("_Palettize", palettize);
    }

    void OnDisable() {
        shaderMat = null;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (DEBUG_SETTINGS)
        {
            //Set variables for our shaders
            shaderMat.SetColor("_ToneVeryLight", palette.veryLightTone);
            shaderMat.SetColor("_ToneLight", palette.lightTone);
            shaderMat.SetColor("_ToneDark", palette.darkTone);
            shaderMat.SetColor("_ToneVeryDark", palette.veryDarkTone);
            if (palettize == 0) { shaderMat.SetFloat("_Spread", spread); }
            else { shaderMat.SetFloat("_Spread", palette.ditherSpread); }
            shaderMat.SetFloat("_BrightnessMultiplier", brightness);
            shaderMat.SetInt("_DitherColorCount", ditherColorCount);
            shaderMat.SetInt("_BayerLevel", bayerLevel);
            shaderMat.SetInt("_Palettize", palettize);
        }

        //Reduce resolution of image
        int width = resolutionWidth;
        int height = resolutionHeight;
        RenderTexture currentSource = source;
        RenderTexture currentDestination = RenderTexture.GetTemporary(width, height, 0, source.format);

        if (pointFilterDown)
            Graphics.Blit(currentSource, currentDestination, shaderMat, 1);
        else
            Graphics.Blit(currentSource, currentDestination);

        currentSource = currentDestination;

        //Apply pixelize effect
        RenderTexture shader = RenderTexture.GetTemporary(width, height, 0, source.format);
        Graphics.Blit(currentSource, shader, shaderMat, 0);

        //Copy the resulting render texture to the destination
        Graphics.Blit(shader, destination, shaderMat, 1);

        //Release the temporary render textures
        RenderTexture.ReleaseTemporary(shader);
    }
}
