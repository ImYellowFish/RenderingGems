using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SSAO : MonoBehaviour {
    public Material occlusionMat;
    public Material blurMat;
    public Vector4[] kernel;
    public int kernelCount = 16;

    private void Update()
    {
        if(occlusionMat != null)
        {
            occlusionMat.SetVectorArray("_Kernel", kernel);
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        RenderTexture occlusion_raw = RenderTexture.GetTemporary(Screen.width, Screen.height);
        Graphics.Blit(source, occlusion_raw, occlusionMat);
        Graphics.Blit(occlusion_raw, destination, blurMat);
        RenderTexture.ReleaseTemporary(occlusion_raw);
    }

    [ContextMenu("Generate")]
    public void Generate()
    {
        kernel = new Vector4[kernelCount];
        for (int i = 0; i < kernelCount; i++)
        {
            kernel[i].x = Random.Range(-1f, 1f);
            kernel[i].y = Random.Range(-1f, 1f);
            kernel[i].z = Random.Range(0f, 1f);
            kernel[i].w = 0;
            kernel[i].Normalize();

            float scale = (float)i / kernelCount;
            scale = Mathf.Lerp(0.1f, 1f, scale * scale);
            kernel[i] *= scale;
        }
    }

    [ContextMenu("GenerateSphere")]
    public void GenerateSphere()
    {
        kernel = new Vector4[kernelCount];
        for (int i = 0; i < kernelCount; i++)
        {
            kernel[i].x = Random.Range(-1f, 1f);
            kernel[i].y = Random.Range(-1f, 1f);
            kernel[i].z = Random.Range(-1f, 1f);
            kernel[i].w = 0;
            kernel[i].Normalize();

            float scale = (float)i / kernelCount;
            scale = Mathf.Lerp(0.1f, 1f, scale * scale);
            kernel[i] *= scale;
        }
    }

    [ContextMenu("GenerateEmpty")]
    public void GenerateEmpty()
    {
        kernel = new Vector4[kernelCount];
        for (int i = 0; i < kernelCount; i++)
        {
            kernel[i].x = 0;
            kernel[i].y = 0;
            kernel[i].z = 1;
            kernel[i].w = 0;
            kernel[i].Normalize();
        }
    }
}
