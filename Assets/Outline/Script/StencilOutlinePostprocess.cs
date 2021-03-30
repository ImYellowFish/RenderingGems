using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StencilOutlinePostprocess : MonoBehaviour {
    public float outlineTexScale = 1.0f;
    [Range(0, 10)]
    public int blurCount = 2;
    [Range(0.1f, 3)]
    public float blurPixelStep = 1.0f;
    [Range(0, 5f)]
    public float outlineStrength = 1.0f;

    public RenderTexture outlineRT;

    private Material outlinePostprocessMaterial;

    // Use this for initialization
    void Start () {
        outlineRT = new RenderTexture(Mathf.NextPowerOfTwo((int)(Screen.width * outlineTexScale)), Mathf.NextPowerOfTwo((int)(Screen.height * outlineTexScale)), 24);
        outlinePostprocessMaterial = new Material(Shader.Find("RGem/StencilOutlinePostprocess"));
    }
	
    private void OnRenderObject()
    {
        if (!outlineRT || !outlinePostprocessMaterial)
            return;
        // Render the outline render texture
        RenderTexture previousActive = RenderTexture.active;

        // choose outline RT as target
        RenderTexture.active = outlineRT;
        // clear outline RT
        GL.Clear(true, true, Color.clear);
        // collect All outline objects
        StencilOutline[] outlineObjects = GameObject.FindObjectsOfType<StencilOutline>();
        foreach(var outlineObj in outlineObjects)
        {
            Material outlineMaterial = outlineObj.OutlineMaterial;
            // Draw outline
            outlineObj.DrawOutline();
        }
        RenderTexture.active = previousActive;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!outlineRT || !outlinePostprocessMaterial)
            return;

        BlurOutline();
        BlendOutlineToScreen(source, destination);
    }

    private void BlurOutline()
    {
        for(int i = 0; i < blurCount; i++)
        {
            RenderTexture tempRT = RenderTexture.GetTemporary(outlineRT.width, outlineRT.height);
            Graphics.Blit(outlineRT, tempRT, outlinePostprocessMaterial, 0);
            Graphics.Blit(tempRT, outlineRT, outlinePostprocessMaterial, 0);
            RenderTexture.ReleaseTemporary(tempRT);
        }
    }

    private void BlendOutlineToScreen(RenderTexture source, RenderTexture destination)
    {
        outlinePostprocessMaterial.SetTexture("_OutlineTex", outlineRT);
        outlinePostprocessMaterial.SetFloat("_OutlineStrength", outlineStrength);
        outlinePostprocessMaterial.SetFloat("_BlurPixelStep", blurPixelStep);
        
        Graphics.Blit(source, destination, outlinePostprocessMaterial, 1);
    }
}
