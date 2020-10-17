using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightShaft : MonoBehaviour {
    public int resolution = 1024;
    public Shader shadowMaskShader;
    public LightShaftObject lightSource;
    public float shadowBias = 0.005f;
    [Header("Readonly")]
    public RenderTexture lightShaftRT;
    public Camera lightShaftCamera;


    private void Start()
    {
        // Allocate shadowRT;
        lightShaftRT = new RenderTexture(resolution, resolution, 0, RenderTextureFormat.ARGB32);
        lightShaftRT.Create();
        lightShaftRT.wrapMode = TextureWrapMode.Clamp;

        // Create light shaft camera
        lightShaftCamera = lightSource.gameObject.AddComponent<Camera>();
        lightShaftCamera.cameraType = CameraType.Game;
        lightShaftCamera.targetTexture = lightShaftRT;
        lightShaftCamera.SetReplacementShader(shadowMaskShader, "");
        lightShaftCamera.clearFlags = CameraClearFlags.Color;
        lightShaftCamera.backgroundColor = Color.white;
        lightShaftCamera.allowMSAA = false;
        lightShaftCamera.allowHDR = false;

        UpdateLightShaftCamera();

        // disable auto rendering
        lightShaftCamera.enabled = false;
    }

    private void UpdateLightShaftCamera()
    {
        lightShaftCamera.nearClipPlane = lightSource.nearClipPlane;
        lightShaftCamera.farClipPlane = lightSource.farClipPlane;
        lightShaftCamera.fieldOfView = lightSource.fieldOfView;
    }

    private void Update()
    {
        UpdateLightShaftCamera();
        
    }

    private Matrix4x4 GetShadowCameraVP()
    {
        Matrix4x4 v = lightShaftCamera.worldToCameraMatrix;
        Matrix4x4 p = lightShaftCamera.projectionMatrix;
        bool d3d = SystemInfo.graphicsDeviceVersion.IndexOf("Direct3D") > -1;
        if (d3d)
        {
            p.m23 = -p.m23 * 0.5f;
            p.m22 = -p.m22 - p.m23 / lightShaftCamera.nearClipPlane;
            p.m11 = -p.m11;
        }
        return p * v;
    }

    private void OnPreRender()
    {
        // update the light shaft transform
        Shader.SetGlobalTexture("_LightShaftTex", lightShaftRT);
        Shader.SetGlobalMatrix("_LightShaftTransform", GetShadowCameraVP());
        Shader.SetGlobalFloat("_gLightShaftDepthBias", shadowBias);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // Render the depth image for lightshaft
        lightShaftCamera.Render();
        Graphics.Blit(source, destination);
    }
}
