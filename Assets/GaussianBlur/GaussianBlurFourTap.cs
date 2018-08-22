using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlurFourTap : MonoBehaviour {
    public int iteration = 5;
    public float blurPixelSpeed = 0.5f;
    public int downSampleCount = 2;
    public Material gaussianBlurMat;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        int blurTexWidth = source.width / downSampleCount;
        int blurTexHeight = source.width / downSampleCount;

        RenderTexture downSampledSource = RenderTexture.GetTemporary(blurTexWidth, blurTexHeight, 0);
        Graphics.Blit(source, downSampledSource);
        source = downSampledSource;

        for (int i = 0; i < iteration; i++)
        {
            RenderTexture blurTarget = RenderTexture.GetTemporary(blurTexWidth, blurTexHeight, 0);
            float pixel_offset = (i + 1) * blurPixelSpeed;
            float uv_offset_x = pixel_offset / source.width;
            float uv_offset_y = pixel_offset / source.height;
            Vector4 uv_offsets = new Vector4(uv_offset_x, uv_offset_y, uv_offset_x, -uv_offset_y);

            gaussianBlurMat.SetVector("_UV_Offset", uv_offsets);
            Graphics.Blit(source, blurTarget, gaussianBlurMat);
            
            RenderTexture.ReleaseTemporary(source);
            source = blurTarget;
        }

        Graphics.Blit(source, destination);
        RenderTexture.ReleaseTemporary(source);
    }
}
