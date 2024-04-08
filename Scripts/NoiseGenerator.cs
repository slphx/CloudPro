using Unity.Collections;
using Unity.Mathematics;
using UnityEngine;
using UnityEditor;

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

        GetComponent<MeshRenderer>().sharedMaterial.SetTexture("_NoiseTex", noiseTex);
        GetComponent<MeshRenderer>().sharedMaterial.SetFloat("_SampleSlice", sliceDepth);

        if (logTimer) {
            Debug.Log("Completed: " + sw.ElapsedMilliseconds + " ms.");
        }
    }

    void OnDisable() {
        noiseTex.Release();
    }

    // https://forum.unity.com/threads/rendertexture-3d-to-texture3d.928362/
    public void Save() {
        string pathWithoutAssetsAndExtension = "test3D";
        int width = noiseTex.width, height = noiseTex.height, depth = noiseTex.volumeDepth;
        var a = new NativeArray<byte>(width * height * depth * 4, Allocator.Persistent, NativeArrayOptions.UninitializedMemory); //change if format is not 8 bits (i was using R8_UNorm) (create a struct with 4 bytes etc)
        UnityEngine.Rendering.AsyncGPUReadback.RequestIntoNativeArray(ref a, noiseTex, 0, (_) =>
        {
            Texture3D output = new Texture3D(width, height, depth, noiseTex.graphicsFormat, UnityEngine.Experimental.Rendering.TextureCreationFlags.None);
            output.SetPixelData(a, 0);
            output.Apply(updateMipmaps: false, makeNoLongerReadable: true);
            AssetDatabase.CreateAsset(output, $"Assets/{pathWithoutAssetsAndExtension}.asset");
            AssetDatabase.SaveAssetIfDirty(output);
            a.Dispose();
            noiseTex.Release();
        });
    }
}
