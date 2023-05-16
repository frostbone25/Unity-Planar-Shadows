using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PlanarShadows
{
    /*
     * Rescales the bounds for the mesh.
     * Since there is no way to turn of frustum culling on meshes,
     * We have to get the mesh and increase its bounds to something super large.
     * 
     * This is to fix the issue with any planar shadow meshes where when the main object is offscreen,
     * the shadow meshes will be culled out due to frustum culling.
     * 
     * NOTE: For VRChat users, or for scenarios where C# script logic can't be run,
     * you can get the mesh after you modify the bounds, and save it to an asset.
     * That way the changes are saved in asset form and can be used in such cases.
    */

    [ExecuteInEditMode]
    public class ShadowMeshBoundsFix : MonoBehaviour
    {
        private MeshFilter meshFilter;
        private SkinnedMeshRenderer skinnedMeshRenderer;

        private void ScaleBounds()
        {
            meshFilter = GetComponent<MeshFilter>();
            skinnedMeshRenderer = GetComponent<SkinnedMeshRenderer>();

            //mesh filters require us to take the original mesh, and create a new copy with modified bounds
            if (meshFilter != null)
            {
                Mesh mesh = meshFilter.sharedMesh;
                Bounds previousBounds = mesh.bounds;
                mesh.bounds = new Bounds(previousBounds.center, Vector3.one * 10000.0f);

                meshFilter.sharedMesh = mesh;
            }

            //skinned mesh renderers are easier as they expose the bounds for us to mess with
            if (skinnedMeshRenderer != null)
            {
                Bounds previousBounds = skinnedMeshRenderer.localBounds;

                skinnedMeshRenderer.allowOcclusionWhenDynamic = false;
                skinnedMeshRenderer.updateWhenOffscreen = false;
                skinnedMeshRenderer.localBounds = new Bounds(previousBounds.center, Vector3.one * 10000.0f);
            }
        }

        private void Awake()
        {
            ScaleBounds();
        }

        private void OnEnable()
        {
            ScaleBounds();
        }
    }
}