using UnityEngine;
using UnityEngine.Rendering.PostProcessing;
using Unity.Mathematics;
using System;

using static Unity.Mathematics.math;

[Serializable]
[PostProcess(typeof(RayMarchBoxRender), PostProcessEvent.AfterStack, "Unity/RayMarchBox")]
public class RayMarchBox: PostProcessEffectSettings
{
    public Vector3Parameter tiling = new Vector3Parameter { value = float3(1.0f) };
    public Vector3Parameter offset = new Vector3Parameter { value = float3(0.0f) };
    [Range(0, 1)]
    public FloatParameter densityThreshold = new FloatParameter { value = 0.0f };
    [Range(0, 5)]
    public FloatParameter densityMultiplier = new FloatParameter { value = 0.0f };
    [Range(1, 256)]
    public IntParameter steps = new IntParameter{ value = 128 };
    public ColorParameter color = new ColorParameter { value = new Color(1f, 1f, 1f, 1f) };
}

public sealed class RayMarchBoxRender: PostProcessEffectRenderer<RayMarchBox>
{
    GameObject box, light;
    Light mainLight;

    override public void Init() {
        box = GameObject.Find("RayMarchBox");
        light = GameObject.Find("Directional Light");
        mainLight = light.GetComponent<Light>();
    }

    public override void Render(PostProcessRenderContext context)
    {
        var cmd = context.command;
        cmd.BeginSample("RayMarchBox");
        
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/RayMarchBox"));
        sheet.properties.SetColor("_Color", settings.color);
        sheet.properties.SetVector("_Tiling", settings.tiling);
        sheet.properties.SetVector("_Offset", settings.offset);
        sheet.properties.SetFloat("_DensityThreshold", settings.densityThreshold);
        sheet.properties.SetFloat("_DensityMultiplier", settings.densityMultiplier);
        sheet.properties.SetInt("_Steps", settings.steps);

        Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(context.camera.projectionMatrix, false);
        sheet.properties.SetMatrix(Shader.PropertyToID("_InverseProjectionMatrix"), projectionMatrix.inverse);
        sheet.properties.SetMatrix(Shader.PropertyToID("_InverseViewMatrix"), context.camera.cameraToWorldMatrix);

        sheet.properties.SetVector(Shader.PropertyToID("_LightDir"), light.transform.rotation*(new Vector3(0, 0, 1)));
        sheet.properties.SetFloat(Shader.PropertyToID("_LightIntensity"), mainLight.intensity);
        sheet.properties.SetVector(Shader.PropertyToID("_LightColor"), mainLight.color);

        Transform boxTransform = box.transform;
        
        float3  A = boxTransform.position - boxTransform.localScale/2.0f,
                B = boxTransform.position + boxTransform.localScale/2.0f;
        float3  bMin = min(A, B),
                bMax = max(A, B);

        sheet.properties.SetVector(Shader.PropertyToID("_BoxMin"), float4(bMin.x, bMin.y, bMin.z, 0.0f));
        sheet.properties.SetVector(Shader.PropertyToID("_BoxMax"), float4(bMax.x, bMax.y, bMax.z, 0.0f));


        NoiseGenerator noiseGenerator = box.GetComponent<NoiseGenerator>();

        sheet.properties.SetTexture(Shader.PropertyToID("_Noise"), noiseGenerator.noiseTex);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
        
        cmd.EndSample("RayMarchBox");
    }
}