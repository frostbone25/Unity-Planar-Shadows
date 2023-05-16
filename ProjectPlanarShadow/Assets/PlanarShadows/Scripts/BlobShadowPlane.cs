using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class BlobShadowPlane : MonoBehaviour
{
    public float planeHeight = 0.005f;

    private void Update()
    {
        transform.position = new Vector3(transform.position.x, planeHeight, transform.position.z);
    }
}
