using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class RenderShadowmap : MonoBehaviour {
    public Light referenceLight;
    public int shadowResolution = 1024;
    public Shader shadowMaskShader;
    public bool outputToScreen;
    public bool toggleDefaultShadow;
    public RenderTextureFormat rtFormat = RenderTextureFormat.Depth;

    [Header("Readonly")]
    public Camera shadowCamera;
    public RenderTexture shadowRT;

    private void Start()
    {
        // Allocate shadowRT;
        shadowRT = new RenderTexture(shadowResolution, shadowResolution, 24, rtFormat);
        Debug.Log(shadowRT.filterMode);
        // Create shadow camera
        GameObject go = new GameObject("_ShadowCamera");
        shadowCamera = go.AddComponent<Camera>();
        shadowCamera.cameraType = CameraType.Game;
        if (!outputToScreen)
            shadowCamera.targetTexture = shadowRT;
        shadowCamera.SetReplacementShader(shadowMaskShader, "");
        shadowCamera.clearFlags = CameraClearFlags.Color;
        shadowCamera.backgroundColor = Color.white;
        shadowCamera.farClipPlane = 20;
        shadowCamera.fieldOfView = 90;
    }

    private void Update()
    {
        if (outputToScreen)
        {
            shadowCamera.targetTexture = null;
        }
        else
        {
            shadowCamera.targetTexture = shadowRT;
        }
        if (toggleDefaultShadow)
        {
            GetComponent<Camera>().SetReplacementShader(Shader.Find("Mobile/Diffuse"), "");
        }
        else
        {
            GetComponent<Camera>().ResetReplacementShader();
        }
        // Place the shadow camera to where the light locates
        shadowCamera.transform.SetPositionAndRotation(referenceLight.transform.position, referenceLight.transform.rotation);
    }

    private Matrix4x4 GetShadowCameraVP()
    {
        Matrix4x4 v = shadowCamera.worldToCameraMatrix;
        Matrix4x4 p = shadowCamera.projectionMatrix;
        bool d3d = SystemInfo.graphicsDeviceVersion.IndexOf("Direct3D") > -1;
        if (d3d)
        {
            p.m23 = -p.m23 * 0.5f;
            p.m22 = -p.m22 - p.m23 / shadowCamera.nearClipPlane;
            p.m11 = -p.m11;
        }
        return p * v;
    }

    private void OnPreRender()
    {
        Shader.SetGlobalTexture("_MyShadowTex", shadowRT);
        shadowCamera.SetReplacementShader(shadowMaskShader, "");
        Shader.SetGlobalMatrix("_MyShadowMatrixVP", GetShadowCameraVP());
        Shader.SetGlobalVector("_MyShadowLightDir", shadowCamera.transform.forward);
    }

    //private void OnWillRenderObject()
    //{
    //    CommandBuffer cb = new CommandBuffer();
    //    shadowCamera.SetReplacementShader(shadowMaskShader, "");
    //    cb.SetRenderTarget(shadowRT);
    //    cb.SetGlobalTexture("_MyShadowTex", shadowRT);
    //    shadowCamera.AddCommandBuffer(CameraEvent.BeforeDepthTexture, cb);
    //    shadowCamera.RenderWithShader()
    //}

    private void OnDestroy()
    {
        shadowRT.Release();
    }
}
