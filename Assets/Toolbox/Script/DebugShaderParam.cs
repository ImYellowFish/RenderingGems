using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class DebugShaderParam : MonoBehaviour {
    public enum GLStateMatrixStage { Update = 0,
        OnRenderImageBegin = 1, OnRenderImageEnd = 2, OnPostRender = 3, OnPreRender = 4}
    [Header("Config")]
    public GLStateMatrixStage glstateMatrixStage;

    [Header("Result")]
    public float width_2_height;
    public GraphicsDeviceType graphicsDeviceType;
    public Matrix4x4 glstate_matrix_projection;
    public Matrix4x4 unity_CameraProjection;
    public Matrix4x4 unity_CameraInvProjection;
    public Matrix4x4 mb_CameraProjection;
    public Matrix4x4 mb_GPUProjection_0;
    public Matrix4x4 mb_GPUProjection_rt;

    public Vector4 _ProjectionParams;
    private Camera targetCamera;
    private void Start()
    {
        graphicsDeviceType = SystemInfo.graphicsDeviceType;
        targetCamera = GetComponent<Camera>();
        if(targetCamera == null)
        {
            targetCamera = Camera.main;
        }
    }

    // Update is called once per frame
    void Update () {
        width_2_height = Screen.width / (float)Screen.height;
        unity_CameraProjection = Shader.GetGlobalMatrix("unity_CameraProjection");
        unity_CameraInvProjection = Shader.GetGlobalMatrix("unity_CameraInvProjection");
        if(glstateMatrixStage == GLStateMatrixStage.Update)
            glstate_matrix_projection = Shader.GetGlobalMatrix("glstate_matrix_projection");
        mb_CameraProjection = targetCamera.projectionMatrix;
        mb_GPUProjection_0 = GL.GetGPUProjectionMatrix(targetCamera.projectionMatrix, false);
        mb_GPUProjection_rt = GL.GetGPUProjectionMatrix(targetCamera.projectionMatrix, true);
        

        _ProjectionParams = Shader.GetGlobalVector("_ProjectionParams");
    }

    private void OnPreRender()
    {
        if (glstateMatrixStage == GLStateMatrixStage.OnPreRender)
            glstate_matrix_projection = Shader.GetGlobalMatrix("glstate_matrix_projection");
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (glstateMatrixStage == GLStateMatrixStage.OnRenderImageBegin)
            glstate_matrix_projection = Shader.GetGlobalMatrix("glstate_matrix_projection");
        Graphics.Blit(source, destination);
        if (glstateMatrixStage == GLStateMatrixStage.OnRenderImageEnd)
            glstate_matrix_projection = Shader.GetGlobalMatrix("glstate_matrix_projection");
    }

    private void OnPostRender()
    {
        if (glstateMatrixStage == GLStateMatrixStage.OnPostRender)
            glstate_matrix_projection = Shader.GetGlobalMatrix("glstate_matrix_projection");
    }
}
