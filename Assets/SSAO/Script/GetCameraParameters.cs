using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GetCameraParameters : MonoBehaviour {
    private Camera _camera;
    public Matrix4x4 cameraProjMat;
    public Matrix4x4 gpu_camPojMat;
    public Matrix4x4 invCameraProjMat;
    // Use this for initialization
	void Start () {
        _camera = GetComponent<Camera>();

    }
	
	// Update is called once per frame
	void Update () {
        if (_camera == null)
            return;

        cameraProjMat = _camera.projectionMatrix;
        invCameraProjMat = _camera.projectionMatrix.inverse;
        gpu_camPojMat = GL.GetGPUProjectionMatrix(cameraProjMat, false);
    }
}
