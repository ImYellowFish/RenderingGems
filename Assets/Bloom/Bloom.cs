using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : MonoBehaviour {
    public Material bloomMat;
    public int iterations = 4;
    public bool useUpSampleIteration = true;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        RenderTexture filtered = RenderTexture.GetTemporary(source.width, source.height, 0);
        Graphics.Blit(source, filtered, bloomMat, 0);

        RenderTexture[] downSamples = new RenderTexture[iterations+1];
        downSamples[0] = filtered;
        int rt_width = source.width;
        int rt_height = source.height;

        for (int i = 0; i < iterations; i++)
        {
            rt_width /= 2;
            rt_height /= 2;

            downSamples[i+1] = RenderTexture.GetTemporary(rt_width, rt_height, 0);
            Graphics.Blit(downSamples[i], downSamples[i+1], bloomMat, 1);
        }

        
        if (useUpSampleIteration)
        {
            // replace downSamples[0] with source
            // so the last combine will include source color
            RenderTexture.ReleaseTemporary(downSamples[0]);
            downSamples[0] = source;

            RenderTexture previousUpsample = downSamples[iterations];
            for (int i = 1; i <= iterations; i++)
            {
                RenderTexture downSampleTex = downSamples[iterations - i];
                RenderTexture currentUpSample = RenderTexture.GetTemporary(downSampleTex.width, downSampleTex.height);
                bloomMat.SetTexture("_BloomTex", downSampleTex);
                Graphics.Blit(previousUpsample, currentUpSample, bloomMat, 2);
                RenderTexture.ReleaseTemporary(previousUpsample);
                previousUpsample = currentUpSample;
            }

            Graphics.Blit(previousUpsample, destination);
            RenderTexture.ReleaseTemporary(previousUpsample);

            // Clean up
            for (int i = 1; i < iterations; i++)
            {
                RenderTexture.ReleaseTemporary(downSamples[i]);
            }
        }

        else
        {
            bloomMat.SetTexture("_BloomTex", source);
            Graphics.Blit(downSamples[iterations], destination, bloomMat, 2);
            // Clean up
            for (int i = 0; i < iterations+1; i++)
            {
                RenderTexture.ReleaseTemporary(downSamples[i]);
            }
        }
        
    }
}
