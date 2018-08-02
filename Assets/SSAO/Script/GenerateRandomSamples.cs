using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GenerateRandomSamples : MonoBehaviour {
    public int sampleCount = 16;
    public Vector3[] samples;
    public string sampleString;

	// Use this for initialization
    [ContextMenu("Generate")]
	public void Generate () {
        samples = new Vector3[sampleCount];
		for(int i = 0; i < sampleCount; i++)
        {
            samples[i].x = Random.Range(-1f, 1f);
            samples[i].y = Random.Range(-1f, 1f);
            samples[i].z = Random.Range(0f, 1f);
            samples[i].Normalize();

            float scale = (float)i / sampleCount;
            scale = Mathf.Lerp(0.1f, 1f, scale * scale);
            samples[i] *= scale;
        }

        sampleString = "";
        for(int i = 0; i < sampleCount; i++)
        {
            sampleString += string.Format("float3({0},{1},{2})", samples[i].x, samples[i].y, samples[i].z);
            if(i < sampleCount - 1)
            {
                sampleString += ",\n";
            }
        }
	}
}
