using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class SkinningBaker : MonoBehaviour {
	public GameObject target;
	public SkinnedMeshRenderer srenderer;
	public AnimationClip clip;

	// How to handle end frame?
	public int sampleRate = 30;
    public string texSavePath = "Assets/Generated/Texture/";
    public string meshSavePath = "Assets/Generated/Mesh/";

    [ContextMenu("Play")]
	public void Play(){
        if (Application.isEditor && Application.isPlaying)
        {
            StartCoroutine(PlayCoroutine());
        }
	}

	private IEnumerator PlayCoroutine(){
		float t = 0;

		while(t < clip.length){
			clip.SampleAnimation(target, t);

			t += Time.deltaTime;
			yield return null;
		}

		clip.SampleAnimation(target, 0);
	}

    [ContextMenu("Bake")]
	public void Bake(){
#if UNITY_EDITOR
        float length = clip.length;
		int samples = Mathf.CeilToInt(length * sampleRate);
		float sampleInterval = 1 / sampleRate;
        int boneCount = srenderer.bones.Length;

        Texture2D texTsl = new Texture2D(boneCount, samples, TextureFormat.RGBA32, false);
		Texture2D texRot = new Texture2D(boneCount, samples, TextureFormat.RGBA32, false);

		for(int frame = 0; frame < samples; frame++){
			float t = Mathf.Clamp(frame * sampleInterval, 0, length);
			clip.SampleAnimation(target, t);

			for(int b = 0; b < boneCount; b++){
				var matrix = srenderer.bones[b].localToWorldMatrix * srenderer.sharedMesh.bindposes[b];
				Vector3 translation = matrix.GetColumn(3);
				Quaternion rotation = Quaternion.LookRotation(matrix.GetColumn(2), matrix.GetColumn(1));

				texTsl.SetPixel(b, frame, EncodeTranslation(translation));
				texRot.SetPixel(b, frame, EncodeQuaternion(rotation));
			}
		}

		texTsl.Apply();
		texRot.Apply();

        string texTslPath = texSavePath + "texTsl.png";
        string texRotPath = texSavePath + "texRot.png";
        File.WriteAllBytes(texTslPath, texTsl.EncodeToPNG());
        File.WriteAllBytes(texRotPath, texRot.EncodeToPNG());

        AssetDatabase.Refresh();
#endif
    }

	private Color EncodeQuaternion(Quaternion rot){
		Color result;
		result.a = rot.w * 0.5f + 0.5f;
		result.r = rot.x * 0.5f + 0.5f;
		result.g = rot.y * 0.5f + 0.5f;
		result.b = rot.z * 0.5f + 0.5f;
		return result;
	}

    [ContextMenu("BakeMesh")]
    public void BakeMesh()
    {
        Mesh oldMesh = srenderer.sharedMesh;
        Mesh mesh = new Mesh();
        mesh.vertices = oldMesh.vertices;
        mesh.triangles = oldMesh.triangles;
        mesh.normals = oldMesh.normals;
        mesh.uv = oldMesh.uv;

        Color[] colors = new Color[mesh.vertices.Length];
        for(int i = 0; i < oldMesh.boneWeights.Length; i++)
        {
            var bw = oldMesh.boneWeights[i];
            colors[i] = GetImportantBoneWeight(bw);
        }
        mesh.colors = colors;
        
#if UNITY_EDITOR
        AssetDatabase.CreateAsset(mesh, meshSavePath + "gpuskin_mesh.asset");
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
#endif
    }

    private struct BoneIndexWeight
    {
        public int index;
        public float weight;

        public BoneIndexWeight(int index, float weight)
        {
            this.index = index;
            this.weight = weight;
        }
    }

    private Color GetImportantBoneWeight(BoneWeight bw)
    {
        List<BoneIndexWeight> tmpBw = new List<BoneIndexWeight>();
        tmpBw.Add(new BoneIndexWeight(bw.boneIndex0, bw.weight0));
        tmpBw.Add(new BoneIndexWeight(bw.boneIndex1, bw.weight1));
        tmpBw.Add(new BoneIndexWeight(bw.boneIndex2, bw.weight2));
        tmpBw.Add(new BoneIndexWeight(bw.boneIndex3, bw.weight3));

        tmpBw.Sort((a, b) => -a.weight.CompareTo(b.weight));

        int index0, index1;
        float weight0, weight1;

        index0 = tmpBw[0].index;
        index1 = tmpBw[1].index;

        float totalWeight = tmpBw[0].weight + tmpBw[1].weight;
        weight0 = tmpBw[0].weight / totalWeight;
        weight1 = tmpBw[1].weight / totalWeight;

        Color c;
        c.r = index0 / 127.0f;
        c.g = weight0;
        c.b = index1 / 127.0f;
        c.a = weight1;

        return c;
    }
    
    // assume pos range from -8 ~ 8
    private Color EncodeTranslation(Vector3 pos){
		AssertAbsLessThan(pos.x, 8f, "pos.x overflows!");
		AssertAbsLessThan(pos.y, 8f, "pos.y overflows!");
		AssertAbsLessThan(pos.z, 8f, "pos.z overflows!");

		Color result;
		result.a = 8f / 256f;
		result.r = (pos.x + 8f) / 16f;
		result.g = (pos.y + 8f) / 16f;
		result.b = (pos.z + 8f) / 16f;

        return result;
	}

	private bool AssertAbsLessThan(float value, float maxValue, string errorMsg){
		if(value > maxValue || value < -maxValue){
			Debug.LogError(errorMsg + "  value: " + value);
			return false;
		}
		return true;
	}
}