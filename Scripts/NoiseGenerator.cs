using Unity.Collections;
using Unity.Mathematics;
using UnityEngine;

[ExecuteInEditMode]
public class NoiseGenerator : MonoBehaviour
{
    [SerializeField]
    ComputeShader noiseCompute;

    public enum NoiseType {Hash, Perlin2D, Perlin3D, Worley2D, Worley3D, PerlinWorley};

    public NoiseType noiseType;

    [SerializeField, Range(1, 256)]
    int resolution = 128;

    [SerializeField]
    int seed = 0;

    [SerializeField, Range(1, 20)]
    int frequency = 4;

    [SerializeField]
    bool isTiling = false;


    [SerializeField, Range(1, 8)]
    int octaves = 1;

    [SerializeField, Range(0, 1)]
    float sliceDepth = 0;

    [SerializeField]
    bool inverse = false;

    [SerializeField]
    bool logTimer = false;

    [Tooltip("需使用 NoisePlane.Mat")]
    [SerializeField]
    bool visualize = false;

    public RenderTexture noiseTex;

    int length;


    const int threadGroupSize = 8;


    void OnValidate() {
        if (seed < 0) seed = 0;

        var sw = System.Diagnostics.Stopwatch.StartNew();

        length = resolution * resolution;

        if (noiseTex == null || !noiseTex.IsCreated() || noiseTex.width != resolution) {
            if (noiseTex != null) {
                noiseTex.Release();
            }
            noiseTex = new RenderTexture(resolution, resolution, 0);
            noiseTex.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
            noiseTex.volumeDepth = resolution;
            noiseTex.enableRandomWrite = true;
            // noiseTex.useMipMap = true;
            noiseTex.Create();
        }

        if (noiseType == NoiseType.Hash)
            noiseTex.filterMode = FilterMode.Point;
        else noiseTex.filterMode = FilterMode.Bilinear;

        // if (!isTiling) 
        //     noiseTex.wrapMode = TextureWrapMode.Repeat;
        // else noiseTex.wrapMode = TextureWrapMode.Repeat;
        noiseTex.wrapMode = TextureWrapMode.Repeat;

        int kernel = noiseCompute.FindKernel("NoiseGenMain");
        noiseCompute.SetInt("_NoiseType", (int)noiseType);
        noiseCompute.SetInt("_Resolution", resolution);
        noiseCompute.SetFloat("_InvResolution", 1.0f/resolution);
        noiseCompute.SetInt("_Seed", seed);
        noiseCompute.SetInt("_Frequency", frequency);
        noiseCompute.SetBool("_IsTiling", isTiling);
        noiseCompute.SetInt("_Octaves", octaves);
        noiseCompute.SetBool("_Inverse", inverse);
        noiseCompute.SetTexture(kernel, "_Noise", noiseTex);

        int numThreadGroups = Mathf.CeilToInt(resolution / (float)threadGroupSize);
        noiseCompute.Dispatch(kernel, numThreadGroups, numThreadGroups, numThreadGroups);

        if (visualize) {
            GetComponent<MeshRenderer>().sharedMaterial.SetTexture("_NoiseTex", noiseTex);
            GetComponent<MeshRenderer>().sharedMaterial.SetFloat("_SampleSlice", sliceDepth);
        }

        if (logTimer) {
            Debug.Log("Completed: " + sw.ElapsedMilliseconds + " ms.");
        }
    }

    void OnDisable() {
        noiseTex.Release();
    }
}
