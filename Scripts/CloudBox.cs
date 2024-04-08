using UnityEngine;
using Unity.Mathematics;
using System;

using static Unity.Mathematics.math;


[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class CloudBox : MonoBehaviour {

    [SerializeField]
    Light sun;

    [SerializeField]
    GameObject noiseObject, boxObject;

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

    Shader shader;
    Material material;


    void Start() {
        if (sun == null) sun = GameObject.Find("Directional Light").GetComponent<Light>();

        shader = Shader.Find("Custom/CloudBox");

        material = new Material(shader);
        material.hideFlags = HideFlags.HideAndDontSave;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        // var cmd = context.command;
        // cmd.BeginSample("RayMarchBox");

        var projectionMatrix = GL.GetGPUProjectionMatrix(Camera.current.projectionMatrix, false);
        material.SetMatrix("_InverseViewMatrix", Camera.current.worldToCameraMatrix.inverse);
        material.SetMatrix("_InverseProjectionMatrix", projectionMatrix.inverse);

        material.SetTexture("_MainTex", src);

        // cloud
        material.SetVector("_Scale", scale);
        material.SetVector("_Offset", offset);
        material.SetFloat("_DensityThreshold", densityThreshold);
        material.SetFloat("_DensityMultiplier", densityMultiplier);
        material.SetFloat("_LightCloudCoef", lightCloudCoef);
        material.SetFloat("_CloudAmbient", cloudAmbient);

        // sun
        material.SetVector("_LightDir", sun.transform.rotation*(new Vector3(0, 0, 1)));
        material.SetVector("_LightColor", sun.color);
        material.SetFloat("_LightIntensity", sun.intensity);


        // box
        Transform boxTransform = boxObject.transform;
        
        float3  A = boxTransform.position - boxTransform.localScale/2.0f,
                B = boxTransform.position + boxTransform.localScale/2.0f;
        float3  bMin = min(A, B),
                bMax = max(A, B);

        material.SetVector(Shader.PropertyToID("_BoxMin"), float4(bMin.x, bMin.y, bMin.z, 0.0f));
        material.SetVector(Shader.PropertyToID("_BoxMax"), float4(bMax.x, bMax.y, bMax.z, 0.0f));


        // noise
        NoiseGenerator noiseGenerator = noiseObject.GetComponent<NoiseGenerator>();

        material.SetTexture(Shader.PropertyToID("_NoiseTex"), noiseGenerator.noiseTex);

        Graphics.Blit(src, dest, material);        
        // cmd.EndSample("RayMarchBox");
    }
}