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
    
    [System.Serializable]
    public class DebugBoneStat
    {
        [System.Serializable]
        public class boneData
        {
            public Vector4[] frames;
        }

        public boneData[] bones;

        public DebugBoneStat(int sampleCount, int boneCount)
        {
            bones = new boneData[boneCount];

            for(int i = 0; i < boneCount; i++)
            {
                bones[i] = new boneData() { frames = new Vector4[sampleCount] };
            }
        }
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

        DebugBoneStat stat = new DebugBoneStat(samples, boneCount);

		for(int frame = 0; frame < samples; frame++){
			float t = Mathf.Clamp((float)frame * sampleInterval, 0, length);
			clip.SampleAnimation(target, t);
            
            for(int b = 0; b < boneCount; b++){
				var bonematrix = srenderer.bones[b].localToWorldMatrix * srenderer.sharedMesh.bindposes[b];
                Matrix4x4 matrix = target.transform.worldToLocalMatrix * bonematrix;
                Vector3 translation = matrix.GetColumn(3);
				Quaternion rotation = GetQuaternionFromMatrix(matrix);
                
				texTsl.SetPixel(b, frame, EncodeTranslation(translation));
				texRot.SetPixel(b, frame, EncodeQuaternion(rotation));

                stat.bones[b].frames[frame] = new Vector4(rotation.x, rotation.y, rotation.z, rotation.w);
			}
		}

		texTsl.Apply();
		texRot.Apply();

        var json = JsonUtility.ToJson(stat, true);
        File.WriteAllText("Assets/debug_bones.txt", json);

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

    private Quaternion GetQuaternionFromMatrix(Matrix4x4 m)
    {
        Quaternion q = new Quaternion();
        q.w = Mathf.Sqrt(Mathf.Max(0, 1 + m[0, 0] + m[1, 1] + m[2, 2])) / 2;
        q.x = Mathf.Sqrt(Mathf.Max(0, 1 + m[0, 0] - m[1, 1] - m[2, 2])) / 2;
        q.y = Mathf.Sqrt(Mathf.Max(0, 1 - m[0, 0] + m[1, 1] - m[2, 2])) / 2;
        q.z = Mathf.Sqrt(Mathf.Max(0, 1 - m[0, 0] - m[1, 1] + m[2, 2])) / 2;
        q.x *= Mathf.Sign(q.x * (m[2, 1] - m[1, 2]));
        q.y *= Mathf.Sign(q.y * (m[0, 2] - m[2, 0]));
        q.z *= Mathf.Sign(q.z * (m[1, 0] - m[0, 1]));
        return q;
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
    private static readonly float MAX_POS_COORD = 8f;
    private Color EncodeTranslation(Vector3 pos){
		AssertAbsLessThan(pos.x, MAX_POS_COORD, "pos.x overflows!");
		AssertAbsLessThan(pos.y, MAX_POS_COORD, "pos.y overflows!");
		AssertAbsLessThan(pos.z, MAX_POS_COORD, "pos.z overflows!");

		Color result;
		result.a = MAX_POS_COORD / 256f;
		result.r = pos.x / MAX_POS_COORD / 2 + 0.5f;
		result.g = pos.y / MAX_POS_COORD / 2 + 0.5f;
		result.b = pos.z / MAX_POS_COORD / 2 + 0.5f;

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