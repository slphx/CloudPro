using System.Collections;
using System.Collections.Generic;
using UnityEngine;

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


        Graphics.Blit(src, dest, material);
    }
}
