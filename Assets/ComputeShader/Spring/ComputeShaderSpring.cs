using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComputeShaderSpring : MonoBehaviour {
    public ComputeShader springComputeShader;
    public int springParticleResolution = 16;
    public float springParticleDistance = 0.1f;
    public float springParticleStiffnessSelf = 0.5f;
    public float springParticleStiffnessNeighbor = 0.5f;
    public Vector3 springGravity = new Vector3(0.0f, -0.1f, 0.0f);
    public float timeScale = 5.0f;
    public Mesh instanceMesh;
    public Material instanceMaterial;
    public bool step;
    public bool trigger;

    ComputeBuffer[] positionBuffers;
    int swapIndex = 0;

    ComputeBuffer argsBuffer;

    public uint[] args = new uint[5] { 0, 0, 0, 0, 0 };

    // Use this for initialization
    void Start () {
        positionBuffers = new ComputeBuffer[3];
        Vector3[] zeroVector3Array = new Vector3[springParticleResolution * springParticleResolution];
        for (int i = 0; i < 3; ++i)
        {
            positionBuffers[i] = new ComputeBuffer(springParticleResolution * springParticleResolution, sizeof(float) * 3);
            positionBuffers[i].SetData(zeroVector3Array);
        }
        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);

        const int submeshIndex = 0;
        args[0] = instanceMesh.GetIndexCount(submeshIndex);
        args[1] = (uint)(springParticleResolution * springParticleResolution);
        args[2] = instanceMesh.GetIndexStart(submeshIndex);
        args[3] = instanceMesh.GetBaseVertex(submeshIndex);
        args[4] = 0;
        argsBuffer.SetData(args);
    }

    private void OnDestroy()
    {
        for (int i = 0; i < 3; ++i)
        {
            positionBuffers[i].Release();
        }
        argsBuffer.Release();
    }

    // Update is called once per frame
    void Update () {
		if(!springComputeShader)
        {
            return;
        }

        if(step)
        {
            if(trigger)
            {
                trigger = false;
            }
            else
            {
                Graphics.DrawMeshInstancedIndirect(instanceMesh, 0, instanceMaterial, new Bounds(Vector3.zero, Vector3.one * 100), argsBuffer);
                return;
            }
        }

        springComputeShader.SetBuffer(0, "_PrevPositions", positionBuffers[swapIndex % 3]);
        springComputeShader.SetBuffer(0, "_Positions", positionBuffers[(swapIndex+1) % 3]);
        springComputeShader.SetBuffer(0, "_NextPositions", positionBuffers[(swapIndex + 2) % 3]);

        swapIndex = (swapIndex + 1) % 3;

        springComputeShader.SetFloat("_ParticleStep", springParticleDistance);
        springComputeShader.SetFloat("_StiffnessSelf", springParticleStiffnessSelf);
        springComputeShader.SetFloat("_StiffnessNeighbor", springParticleStiffnessNeighbor);
        springComputeShader.SetFloat("_Resolution", springParticleResolution);
        springComputeShader.SetFloats("_Gravity", springGravity.x, springGravity.y, springGravity.z);
        springComputeShader.SetFloat("_DeltaTime", Time.deltaTime * timeScale);

        int groupCount = Mathf.CeilToInt(springParticleResolution / 8.0f);
        springComputeShader.Dispatch(0, groupCount, groupCount, 1);

        instanceMaterial.SetBuffer("_Positions", positionBuffers[swapIndex]);
        instanceMaterial.SetFloat("_ParticleStep", springParticleDistance);
        instanceMaterial.SetFloat("_Resolution", springParticleResolution);


        Graphics.DrawMeshInstancedIndirect(instanceMesh, 0, instanceMaterial, new Bounds(Vector3.zero, Vector3.one * 100), argsBuffer);
        
    }
}
