using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SimpleBlit : MonoBehaviour {
    public Material[] blitMaterial;
    
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(blitMaterial.Length > 0)
        {
            RenderTexture intermediate_source = source;
            RenderTexture intermediate_dest = source;
            for(int i = 0; i < blitMaterial.Length; i++)
            {
                if(i == 0)
                {
                    intermediate_source = source;
                }
                else
                {
                    intermediate_source = intermediate_dest;
                }

                if(i == blitMaterial.Length - 1)
                {
                    intermediate_dest = destination;
                }
                else
                {
                    intermediate_dest = RenderTexture.GetTemporary(Screen.width, Screen.height);
                }
                Graphics.Blit(intermediate_source, intermediate_dest, blitMaterial[i]);

                if (i > 0)
                {
                    RenderTexture.ReleaseTemporary(intermediate_source);
                }
            }
        }
        else
        {
            Graphics.Blit(source, destination);
        }   
    }
}
