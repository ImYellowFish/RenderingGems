using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestPerObjProjection : MonoBehaviour {
    
	// Update is called once per frame
	void Update () {
        Matrix4x4 proj = Camera.main.projectionMatrix;
        Matrix4x4 gpuProj = GL.GetGPUProjectionMatrix(proj, false);
        Matrix4x4 gpuProjRT = GL.GetGPUProjectionMatrix(proj, true);
        Shader.SetGlobalMatrix("_GLGPUProjMatrix", gpuProj);
        Shader.SetGlobalMatrix("_GLGPUProjRTMatrix", gpuProjRT);
	}
}
