using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShowBones : MonoBehaviour {
    public Transform[] bones;
	// Use this for initialization
	void Start () {
        var rd = GetComponent<SkinnedMeshRenderer>();
        bones = rd.bones;
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
