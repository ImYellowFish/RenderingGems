using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SunShaft : MonoBehaviour {
    public Transform sun;
    public Material sunShaftMaterial;
    public Material sunShaftExtractLightMaterial;
    public int downSample = 2;
    [Header("ReadOnly")]
    public Vector3 sunScreenPos;
    public RenderTexture buffer;
    private Camera cam;


	// Use this for initialization
	void Start () {
        cam = GetComponent<Camera>();
    }
	
	// Update is called once per frame
	void Update () {
        if (cam)
        {
            var sunWorldPos = sun.position;
            sunScreenPos = cam.WorldToViewportPoint(sunWorldPos);
            if (sunShaftMaterial)
                sunShaftMaterial.SetVector("_SunScreenPos", sunScreenPos);
        }
	}

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // To use stencil buffer on postfx, 
        // see https://answers.unity.com/questions/621279/using-the-stencil-buffer-in-a-post-process.html
        if (sunShaftMaterial && sunShaftExtractLightMaterial)
        {
            buffer = RenderTexture.GetTemporary(Screen.width, Screen.height, 24);
            Graphics.SetRenderTarget(buffer.colorBuffer, source.depthBuffer);
            Graphics.Blit(source, buffer, sunShaftExtractLightMaterial);
            Shader.SetGlobalTexture("_SunShaftLightTex", buffer);
            Graphics.Blit(source, destination, sunShaftMaterial, 0);
            RenderTexture.ReleaseTemporary(buffer);
        }
        else
            Graphics.Blit(source, destination);
    }
}
