using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SSR : MonoBehaviour {
    public Material ssrMat;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        ssrMat.SetMatrix("_ViewMatrix", Camera.main.worldToCameraMatrix);
        Graphics.Blit(source, destination, ssrMat);
    }
}
