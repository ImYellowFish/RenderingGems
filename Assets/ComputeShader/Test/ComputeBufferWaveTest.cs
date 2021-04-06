using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComputeBufferWaveTest : MonoBehaviour {
    public int gridDimension;
    public float step = 0.1f;

    public const int threadDimension = 8;
    public ComputeShader computeShader;
    ComputeBuffer computeBuffer;

    ComputeBuffer argsBuffer;
    // index count per instance, instance count, start index location, base vertex location, start instance location
    public uint[] args = new uint[5] { 0, 0, 0, 0, 0};

    public Mesh mesh;
    public Material material;
    public Bounds bound;

    // Use this for initialization
    void Start () {
        computeBuffer = new ComputeBuffer(gridDimension * gridDimension, sizeof(float) * 3);
        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);

        const int submeshIndex = 0;
        args[0] = mesh.GetIndexCount(submeshIndex);
        args[1] = (uint)(gridDimension * gridDimension);
        args[2] = mesh.GetIndexStart(submeshIndex);
        args[3] = mesh.GetBaseVertex(submeshIndex);
        args[4] = 0;
        argsBuffer.SetData(args);


    }

    // Update is called once per frame
    void Update () {
		if(computeShader)
        {
            computeShader.SetBuffer(0, "_Positions", computeBuffer);
            computeShader.SetFloat("_Resolution", gridDimension);
            computeShader.SetFloat("_Step", step);
            computeShader.SetFloat("_Time", Time.time);

            float geoSize = gridDimension * step;
            bound = new Bounds(new Vector3(0, 0, 0), new Vector3(geoSize, geoSize, geoSize));

            int groupCount = Mathf.CeilToInt(gridDimension / threadDimension);
            computeShader.Dispatch(0, groupCount, groupCount, 1);

            material.SetBuffer("_Positions", computeBuffer);
            material.SetFloat("_Step", step);
            Graphics.DrawMeshInstancedIndirect(mesh, 0, material, bound, argsBuffer);
        }
	}

    private void OnDestroy()
    {
        computeBuffer.Release();
        computeBuffer = null;
        argsBuffer.Release();
        argsBuffer = null;
    }
}
