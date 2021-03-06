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
    public bool oneFrameOnly = false;
    public string texSavePath = "Assets/GPUSkinning/Example/Generated/Test";
    public string meshSavePath = "Assets/GPUSkinning/Example/Generated/Test";

    [ContextMenu("Play")]
	public void Play(){
        if (Application.isEditor && Application.isPlaying)
        {
            StartCoroutine(PlayCoroutine());
        }
	}

	private IEnumerator PlayCoroutine(){
		float t = 0;
        Debug.Log("is humanoid:" + clip.isHumanMotion);
		while(t < clip.length){
            SampleAnimation(t);

            t += Time.deltaTime;
			yield return null;
		}

		SampleAnimation(0);
        SampleAnimationEnd();
	}
    
    private void SampleAnimation(float t)
    {
        if (clip == null)
            return;
        if (clip.isHumanMotion)
        {
            SetAnimationMode(true);
            AnimationMode.SampleAnimationClip(target, clip, t);
        }
        else
        {
            clip.SampleAnimation(target, t);
        }
    }

    private void SampleAnimationEnd()
    {
        if (clip == null)
            return;
        if (clip.isHumanMotion)
        {
            SetAnimationMode(false);
        }
    }

    private void SetAnimationMode(bool enabled)
    {
#if UNITY_EDITOR
        if (AnimationMode.InAnimationMode() && !enabled)
            AnimationMode.StopAnimationMode();
        else if(!AnimationMode.InAnimationMode() && enabled)
            AnimationMode.StartAnimationMode();
#endif
    }

    private int GetNextPowOf2(int a)
    {
        return Mathf.NextPowerOfTwo(a);
    }

    [System.Serializable]
    public class DebugBoneStat
    {
        [System.Serializable]
        public class boneData
        {
            [System.NonSerialized]
            public Vector4[] rotations;

            public Vector4[] positions;

            [System.NonSerialized]
            public Matrix4x4[] matrices;
        }

        public boneData[] bones;

        public DebugBoneStat(int sampleCount, int boneCount)
        {
            bones = new boneData[boneCount];

            for(int i = 0; i < boneCount; i++)
            {
                bones[i] = new boneData() { positions = new Vector4[sampleCount], rotations = new Vector4[sampleCount], matrices = new Matrix4x4[sampleCount] };
            }
        }
    }

    [ContextMenu("Bake")]
	public void Bake(){
#if UNITY_EDITOR
        int samples = 1;
        float length = 1.0f / sampleRate;

        if (clip != null)
        {
            length = clip.length;
            samples = Mathf.CeilToInt(length * sampleRate);
            Debug.Log("Clip length: " + length + ", samples: " + samples);
        }

        if(oneFrameOnly)
            samples = 1;

        float sampleInterval = 1f / sampleRate;
        int boneCount = srenderer.bones.Length;
        Debug.Log("Sample count: " + samples);
        Debug.Log("Bone count: " + boneCount);

        Texture2D texTsl = new Texture2D(GetNextPowOf2(boneCount), GetNextPowOf2(samples), TextureFormat.RGBA32, false);
        Texture2D texRot = new Texture2D(GetNextPowOf2(boneCount), GetNextPowOf2(samples), TextureFormat.RGBA32, false);

        DebugBoneStat stat = new DebugBoneStat(samples, boneCount);

		for(int frame = 0; frame < samples; frame++){
			float t = Mathf.Clamp((float)frame * sampleInterval, 0, length);
            SampleAnimation(t);

            for(int b = 0; b < boneCount; b++){
                var bonematrix = srenderer.bones[b].localToWorldMatrix * srenderer.sharedMesh.bindposes[b];
                bonematrix *= Matrix4x4.Scale(bonematrix.lossyScale).inverse;
                Debug.Log(srenderer.bones[b].localToWorldMatrix);
                Debug.Log(srenderer.sharedMesh.bindposes[b]);
                Debug.Log(bonematrix);
                Matrix4x4 matrix = target.transform.worldToLocalMatrix * bonematrix;
                Vector4 translation = matrix.GetColumn(3);
                Quaternion rotation = GetQuaternionFromMatrix(matrix);
                
				texTsl.SetPixel(b, frame, EncodeTranslation(translation));
				texRot.SetPixel(b, frame, EncodeQuaternion(rotation));

                stat.bones[b].rotations[frame] = new Vector4(rotation.x, rotation.y, rotation.z, rotation.w);
                stat.bones[b].positions[frame] = new Vector4(translation.x, translation.y, translation.z, translation.w);
                stat.bones[b].matrices[frame] = matrix;
            }
		}
        SampleAnimationEnd();

		texTsl.Apply();
		texRot.Apply();

        var json = JsonUtility.ToJson(stat, true);
        File.WriteAllText(texSavePath + "debug_json.txt", json);

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
            Debug.Log("c: " + colors[i]);
        }
        mesh.colors = colors;
        
#if UNITY_EDITOR
        AssetDatabase.CreateAsset(mesh, meshSavePath + "gpuskin_mesh.asset");
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
#endif
    }

    private GameObject testMeshGo = null;

    [ContextMenu("TestMesh")]
    public void TestMesh()
    {
        if (testMeshGo)
        {
            DestroyImmediate(testMeshGo);
            testMeshGo = null;
        }

        int boneCount = srenderer.bones.Length;
        var texTsl = new Texture2D(boneCount, 1, TextureFormat.RGBA32, false);
        var texRot = new Texture2D(boneCount, 1, TextureFormat.RGBA32, false);
        for (int b = 0; b < boneCount; b++)
        {
            var bonematrix = srenderer.bones[b].localToWorldMatrix * srenderer.sharedMesh.bindposes[b];
            bonematrix *= Matrix4x4.Scale(bonematrix.lossyScale).inverse;
            Matrix4x4 matrix = target.transform.worldToLocalMatrix * bonematrix;
            Vector4 translation = matrix.GetColumn(3);
            Quaternion rotation = GetQuaternionFromMatrix(matrix);

            texTsl.SetPixel(b, 0, EncodeTranslation(translation));
            texRot.SetPixel(b, 0, EncodeQuaternion(rotation));
        }
        texTsl.Apply();
        texRot.Apply();
        
        Mesh oldMesh = srenderer.sharedMesh;
        var vertices = oldMesh.vertices;
        
        for (int i = 0; i < oldMesh.boneWeights.Length; i++)
        {
            var v0 = vertices[i];
            var bc = GetImportantBoneWeight(oldMesh.boneWeights[i]);

            var ct = texTsl.GetPixel(Mathf.RoundToInt(bc.r * 64.0f), 0);
            var cr = texRot.GetPixel(Mathf.RoundToInt(bc.r * 64.0f), 0);

            //int bone0 = Mathf.RoundToInt(bc.r * 64.0f - 0.5f);
            //var matrix = target.transform.worldToLocalMatrix * srenderer.bones[bone0].localToWorldMatrix * srenderer.sharedMesh.bindposes[bone0];
            //Vector3 translation = matrix.GetColumn(3);
            //var rotation = GetQuaternionFromMatrix(matrix);
            //var ct = EncodeTranslation(translation);
            //var cr = EncodeQuaternion(rotation);

            var rotxyz = new Vector3(cr.r, cr.g, cr.b);
            rotxyz = rotxyz * 2 - Vector3.one;
            float rotw = cr.a * 2f - 1f;
            

            Vector3 v1 = v0 + 2.0f * Vector3.Cross(rotxyz, Vector3.Cross(rotxyz, v0) + rotw * v0);
            Vector3 v2 = v1 + (new Vector3(ct.r, ct.g, ct.b) - Vector3.one * 0.5f) * 16;

            // vertices[i] = matrix.MultiplyPoint(v0);
            vertices[i] = v2;
        }

        Mesh mesh = new Mesh();
        mesh.vertices = vertices;
        mesh.triangles = oldMesh.triangles;
        mesh.normals = oldMesh.normals;
        mesh.uv = oldMesh.uv;

        testMeshGo = new GameObject("TestMesh");
        testMeshGo.hideFlags = HideFlags.DontSave;
        var mr = testMeshGo.AddComponent<MeshRenderer>();
        mr.material = new Material(Shader.Find("Mobile/Diffuse"));
        var mf = testMeshGo.AddComponent<MeshFilter>();
        mf.mesh = mesh;

        DestroyImmediate(texTsl);
        DestroyImmediate(texRot);
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
        c.r = EncodeBoneIndex(index0);
        c.g = weight0;
        c.b = EncodeBoneIndex(index1);
        c.a = weight1;

        return c;
    }

    private float EncodeBoneIndex(int index)
    {
        return index / 64.0f;
    }

    // assume pos range from -8 ~ 8
    private static readonly float MAX_POS_COORD = 8f;
    private Color EncodeTranslation(Vector3 pos){
		AssertAbsLessThan(pos.x, MAX_POS_COORD, "pos.x overflows!");
		AssertAbsLessThan(pos.y, MAX_POS_COORD, "pos.y overflows!");
		AssertAbsLessThan(pos.z, MAX_POS_COORD, "pos.z overflows!");

		Color result;
		result.a = 1f;
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