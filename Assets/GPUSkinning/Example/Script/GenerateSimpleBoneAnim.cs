using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class GenerateSimpleBoneAnim : MonoBehaviour {
    public string assetSavePath = "Assets/GPUSkinning/Example/Generated/";

	[ContextMenu("Test")]
	public void Test () {
        gameObject.AddComponent<Animation>();
        gameObject.AddComponent<SkinnedMeshRenderer>();
        SkinnedMeshRenderer rend = GetComponent<SkinnedMeshRenderer>();
        Animation anim = GetComponent<Animation>();

        // Build basic mesh
        Mesh mesh = new Mesh();
        mesh.vertices = new Vector3[] { new Vector3(-1, 0, 0), new Vector3(1, 0, 0), new Vector3(-1, 5, 0), new Vector3(1, 5, 0) };
        mesh.uv = new Vector2[] { new Vector2(0, 0), new Vector2(1, 0), new Vector2(0, 1), new Vector2(1, 1) };
        mesh.triangles = new int[] { 0, 1, 2, 1, 3, 2 };
        mesh.RecalculateNormals();
        rend.material = new Material(Shader.Find("Diffuse"));

        // assign bone weights to mesh
        BoneWeight[] weights = new BoneWeight[4];
        weights[0].boneIndex0 = 0;
        weights[0].weight0 = 1;
        weights[1].boneIndex0 = 0;
        weights[1].weight0 = 1;
        weights[2].boneIndex0 = 1;
        weights[2].weight0 = 1;
        weights[3].boneIndex0 = 1;
        weights[3].weight0 = 1;
        mesh.boneWeights = weights;

        // Create Bone Transforms and Bind poses
        // One bone at the bottom and one at the top

        Transform[] bones = new Transform[2];
        Matrix4x4[] bindPoses = new Matrix4x4[2];
        bones[0] = new GameObject("Lower").transform;
        bones[0].parent = transform;
        // Set the position relative to the parent
        bones[0].localRotation = Quaternion.identity;
        bones[0].localPosition = Vector3.zero;

        bindPoses[0] = bones[0].worldToLocalMatrix;

        bones[1] = new GameObject("Upper").transform;
        bones[1].parent = transform;
        // Set the position relative to the parent
        bones[1].localRotation = Quaternion.identity;
        bones[1].localPosition = new Vector3(0, 5, 0);

        bindPoses[1] = bones[1].worldToLocalMatrix;

        // bindPoses was created earlier and was updated with the required matrix.
        // The bindPoses array will now be assigned to the bindposes in the Mesh.
        mesh.bindposes = bindPoses;

        // Assign bones and bind poses
        rend.bones = bones;
        rend.sharedMesh = mesh;

        // Assign a simple waving animation to the bottom bone
        AnimationCurve curve = new AnimationCurve();
        curve.keys = new Keyframe[] { new Keyframe(0, 0, 0, 0), new Keyframe(1, 0.6f, 0, 0), new Keyframe(2, 0.0F, 0, 0) };

        AnimationCurve curve2 = new AnimationCurve();
        curve2.keys = new Keyframe[] { new Keyframe(0, 1f, 0, 0), new Keyframe(1, 0.86f, 0, 0), new Keyframe(2, 1.0F, 0, 0) };


        // Create the clip with the curve
        AnimationClip clip = new AnimationClip();
        //clip.SetCurve("Lower", typeof(Transform), "m_LocalPosition.z", curve);

        clip.SetCurve("Lower", typeof(Transform), "m_LocalRotation.z", curve);
        clip.SetCurve("Lower", typeof(Transform), "m_LocalRotation.w", curve2);

        clip.legacy = true;

        // Add and play the clip
        clip.wrapMode = WrapMode.Loop;
        anim.AddClip(clip, "test");
        anim.Play("test");

#if UNITY_EDITOR
        AssetDatabase.CreateAsset(mesh, assetSavePath + "simpleMesh.asset");
        AssetDatabase.CreateAsset(clip, assetSavePath + "simpleClip.asset");
        AssetDatabase.SaveAssets();
#endif
    }
	
}
