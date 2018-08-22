using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlurBilinear : MonoBehaviour {
    public Material gaussianBlurMat;
    public int downSampleCount = 2;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        int downSampleWidth = source.width / downSampleCount;
        int downSampleHeight = source.height / downSampleCount;
        gaussianBlurMat.SetFloat("_TexWidth", downSampleWidth);
        gaussianBlurMat.SetFloat("_TexHeight", downSampleHeight);

        RenderTexture downSampled = RenderTexture.GetTemporary(downSampleWidth, downSampleHeight, 0);
        Graphics.Blit(source, downSampled);
        RenderTexture horizontalBlurred = RenderTexture.GetTemporary(downSampleWidth, downSampleHeight, 0);
        Graphics.Blit(downSampled, horizontalBlurred, gaussianBlurMat, 1);
        Graphics.Blit(horizontalBlurred, downSampled, gaussianBlurMat, 0);

        Graphics.Blit(downSampled, destination);

        RenderTexture.ReleaseTemporary(downSampled);
        RenderTexture.ReleaseTemporary(horizontalBlurred);
    }
}
