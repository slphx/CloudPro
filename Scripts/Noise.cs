using Unity.Collections;
using Unity.Mathematics;
using UnityEngine;

[ExecuteInEditMode]
public class Noise : MonoBehaviour
{
    [SerializeField, Range(1, 256)]
    int resolution = 128;

    [SerializeField, Range(2, 3)]
    int dimension = 2;

    [SerializeField]
    int seed = 0;

    [SerializeField]
    ComputeShader noiseCompute;

    RenderTexture noiseTex;

    const int threadGroupSize = 8;

    int length;

    bool needUpdate = true, is3D = false;

    void OnValidate() {
        needUpdate = true;
        is3D = dimension > 2;
    }

    void OnEnable() {

    }

    void Update() {

        if (needUpdate) {
            length = resolution * resolution;
            if (is3D) length *= resolution;

            if (noiseTex == null || !noiseTex.IsCreated() || noiseTex.width != resolution) {
                if (noiseTex != null) {
                    noiseTex.Release();
                }
                noiseTex = new RenderTexture(resolution, resolution, 0);
                noiseTex.enableRandomWrite = true;
                noiseTex.dimension = UnityEngine.Rendering.TextureDimension.Tex2D;
                noiseTex.Create();
            }

            int kernel = noiseCompute.FindKernel("CSMain");
            noiseCompute.SetInt("_Resolution", resolution);
            noiseCompute.SetFloat("_InvResolution", 1.0f/resolution);
            noiseCompute.SetInt("_Seed", seed);
            noiseCompute.SetTexture(kernel, "_NoiseTex", noiseTex);
            int numThreadGroups = Mathf.CeilToInt(resolution / (float)threadGroupSize);

            noiseCompute.Dispatch(kernel, numThreadGroups, numThreadGroups, 1);

            GetComponent<MeshRenderer>().sharedMaterial.SetTexture("_NoiseTex", noiseTex);
        }
    }

    void OnDisable() {

    }
}
