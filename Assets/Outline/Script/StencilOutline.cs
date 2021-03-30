using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StencilOutline : MonoBehaviour {
    public Color outlineColor = Color.white;
    [Range(0, 0.2f)]
    public float outlineWidth = 0.01f;

    private void Start()
    {
        outlineMesh = GetComponent<MeshFilter>().sharedMesh;
    }

    // Use this on each outline object
    public Material OutlineMaterial
    {
        get
        {
            if (!outlineMaterial)
            {
                outlineMaterial = new Material(Shader.Find("RGem/StencilOutline"));
            }
            outlineMaterial.SetColor("_OutlineColor", outlineColor);
            outlineMaterial.SetFloat("_OutlineWidth", outlineWidth);
            return outlineMaterial;
        }
    }

    public void DrawOutline()
    {
        Material mat = OutlineMaterial;
        Matrix4x4 matrix = transform.localToWorldMatrix;
        // Activate pass 0 in outline material
        mat.SetPass(0);
        // Draw stencil
        Graphics.DrawMeshNow(outlineMesh, matrix);
        // Activate pass 1 in outline material
        mat.SetPass(1);
        // Check stencil and draw outline
        Graphics.DrawMeshNow(outlineMesh, matrix);
    }

    private Material outlineMaterial;
    private Mesh outlineMesh;
}
