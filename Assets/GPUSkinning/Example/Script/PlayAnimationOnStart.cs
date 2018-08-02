using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayAnimationOnStart : MonoBehaviour {
    public string animName = "test";

    void Start()
    {
        Play();
    }

    [ContextMenu("Play")]
    public void Play()
    {
        var anim = GetComponent<Animation>();
        if (anim != null)
        {
            anim.Play(animName);
        }
    }
}
