using UnityEngine;
using Unity.Mathematics;

using static Unity.Mathematics.math;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class CloudSky : MonoBehaviour
{

    [SerializeField]
    Light sun;

    // Atmosphere

    // properties
    [SerializeField, Range(0, 10.0f)]
    float RayleighScatterCoef = 1;
    [SerializeField, Range(0, 10.0f)]
    float RayleighExtinctionCoef = 1;
    [SerializeField, Range(0, 10.0f)]
    float MieScatterCoef = 1;
    [SerializeField, Range(0, 10.0f)]
    float MieExtinctionCoef = 1;
    [SerializeField, Range(0.0f, 0.999f)]
    float MieG = 0.76f;
    [SerializeField]
    Color PlanetColor = new Vector4(0.0f, 0.0f, 0.0f, 0.0f);

    // [SerializeField, Range(0.1f, 10.0f)]
    // float DistanceScale = 1.0f;

    // constants
    const float AtmosphereHeight = 80000.0f;
    const float PlanetRadius = 6371000.0f;
    Vector4 DensityScaleHeight = new Vector4(7994.0f, 1200.0f, 0, 0);
    Vector4 RayleighSct = new Vector4(5.8f, 13.5f, 33.1f, 0.0f) * 1e-6f;
    Vector4 MieSct = new Vector4(2.0f, 2.0f, 2.0f, 0.0f) * 1e-5f;


    // Cloud
    [SerializeField]
    GameObject noiseObject;

    [SerializeField]
    Vector2 cloudHeight = float2(1500f, 4000f);     // 云层覆盖高度

    [SerializeField]
    Vector2 scale = float2(0.001f, 0.01f);    // x 为采样时 pos 的系数，y 为采样时 offset 的系数
    
    [SerializeField]
    Vector3 offset = float3(0.0f);

    [SerializeField, Range(0, 1)]
    float densityThreshold = 0.04f;

    [SerializeField, Range(0, 1)]
    float densityMultiplier = 1.0f;

    [SerializeField, Range(0, 10)]
    float lightCloudCoef = 1.0f;

    [SerializeField, Range(0, 3)]
    float cloudAmbient = 1f;

    [SerializeField]
    Texture2D coverageTex;

    [SerializeField]
    Vector2 coverageOffset = float2(0.0f);

    Shader shader;
    Material material;


    void Start()
    {
        shader = Shader.Find("Custom/CloudSky");

        material = new Material(shader);
        material.hideFlags = HideFlags.HideAndDontSave;

    }

    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        var projectionMatrix = GL.GetGPUProjectionMatrix(Camera.current.projectionMatrix, false);
        material.SetMatrix("_InverseViewMatrix", Camera.current.worldToCameraMatrix.inverse);
        material.SetMatrix("_InverseProjectionMatrix", projectionMatrix.inverse);

        material.SetTexture("_MainTex", src);
        // sun
        material.SetVector("_LightDir", sun.transform.rotation*(new Vector3(0, 0, 1)));
        material.SetVector("_LightColor", sun.color);
        material.SetFloat("_LightIntensity", sun.intensity);

        // planet
        material.SetVector("_PlanetColor", PlanetColor);
        material.SetFloat("_PlanetRadius", PlanetRadius);
        material.SetFloat("_AtmosphereHeight", AtmosphereHeight);
        material.SetVector("_DensityScaleHeight", DensityScaleHeight);
        material.SetVector("_ScatteringR", RayleighSct * RayleighScatterCoef);
        material.SetVector("_ScatteringM", MieSct * MieScatterCoef);
        material.SetVector("_ExtinctionR", RayleighSct * RayleighExtinctionCoef);
        material.SetVector("_ExtinctionM", MieSct * MieExtinctionCoef);
        material.SetFloat("_MieG", MieG);

        // cloud
        material.SetVector("_CloudHeight", cloudHeight);
        material.SetVector("_Scale", scale);
        material.SetVector("_Offset", offset);
        material.SetFloat("_DensityThreshold", densityThreshold);
        material.SetFloat("_DensityMultiplier", densityMultiplier);
        material.SetFloat("_LightCloudCoef", lightCloudCoef);
        material.SetFloat("_CloudAmbient", cloudAmbient);

        // noise
        CloudNoiseGen noiseGenerator = noiseObject.GetComponent<CloudNoiseGen>();

        material.SetTexture(Shader.PropertyToID("_NoiseTex"), noiseGenerator.noiseTex);
        material.SetTexture(Shader.PropertyToID("_CoverageTex"), coverageTex);
        material.SetVector("_CoverageOffset", coverageOffset);

        Graphics.Blit(src, dest, material);
    }
}
