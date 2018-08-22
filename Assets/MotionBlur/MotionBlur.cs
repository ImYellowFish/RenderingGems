using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : MonoBehaviour {
    public Material motionBlurMat;
    public RenderTexture accumulationTex;
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(motionBlurMat == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        if(accumulationTex == null || 
            accumulationTex.width != source.width || accumulationTex.height != source.height)
        {
            DestroyImmediate(accumulationTex);
            accumulationTex = new RenderTexture(source.width, source.height, 0);
            accumulationTex.hideFlags = HideFlags.DontSave;
            Graphics.Blit(source, accumulationTex);
        }

        accumulationTex.MarkRestoreExpected();
        Graphics.Blit(source, accumulationTex, motionBlurMat);
        Graphics.Blit(accumulationTex, destination);
    }
}
