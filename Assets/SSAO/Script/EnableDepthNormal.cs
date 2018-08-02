using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnableDepthNormal : MonoBehaviour {
    public DepthTextureMode mode = DepthTextureMode.DepthNormals;

	// Use this for initialization
	void Start () {
        var cam = GetComponent<Camera>();
        if (cam != null)
        {
            cam.depthTextureMode = mode;
        }
	}
}
