uniform float4x4 _InverseProjectionMatrix;
uniform float4x4 _InverseViewMatrix;

TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);

// cloud
float4 _Color;
float3 _BoxMin;
float3 _BoxMax;
float3 _Tiling;
float3 _Offset;
float _DensityThreshold;
float _DensityMultiplier;

// light
float3 _LightDir;
float _LightIntensity;
float4 _LightColor;

int _Steps;

Texture3D _Noise;
SamplerState sampler_Noise;

                //边界框最小值       边界框最大值         世界相机位置      光线方向倒数
float2 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 invRaydir) 
{
    float3 t0 = (boundsMin - rayOrigin) * invRaydir;
    float3 t1 = (boundsMax - rayOrigin) * invRaydir;
    float3 tmin = min(t0, t1);
    float3 tmax = max(t0, t1);

    float dstA = max(max(tmin.x, tmin.y), tmin.z); //进入点
    float dstB = min(tmax.x, min(tmax.y, tmax.z)); //出去点

    float dstToBox = max(0, dstA);
    float dstInsideBox = max(0, dstB - dstToBox);
    return float2(dstToBox, dstInsideBox);
}

//计算世界空间坐标
float4 GetWorldSpacePosition(float depth, float2 uv)
{
    float4 view_vector = mul(_InverseProjectionMatrix, float4(2.0 * uv - 1.0, depth, 1.0));
    view_vector.xyz /= view_vector.w;

    float4x4 l_matViewInv = _InverseViewMatrix;
    float4 world_vector = mul(l_matViewInv, float4(view_vector.xyz, 1));
    return world_vector;
}

float getDensity(float3 pos) {
    // float3 uvw = (pos - _BoxMin) / (_BoxMax - _BoxMin);
    float3 uvw = pos * _Tiling * 0.01 + _Offset * 0.02;
    // float density = tex3Dlod(_Noise, float4(uvw, 0));
    float density = _Noise.SampleLevel(sampler_Noise, uvw, 0);
    return max(0.0, density - _DensityThreshold) * _DensityMultiplier;
}

float beer(float d) {
    return exp(-d);
}

float powder_sugar_effect(float d) {
    return 2.0 * exp(-d) * (1.0 - exp(-d*2.0));
}

float hg(float a, float g) 
{
  float g2 = g * g;
  return (1 - g2) / (4 * 3.1415 * pow(1 + g2 - 2 * g * (a), 1.5));
}

// float phase(float a) 
// {
//     float blend = 0.5;
//     float hgBlend = hg(a, _phaseParams.x) * (1 - blend) + hg(a, -_phaseParams.y) * blend;
//     return _phaseParams.z + hgBlend * _phaseParams.w;
// }

float lightMarch(float3 position) {
    float3 origin = position;
    float3 dir = _LightDir;
    float2 rayToBox = rayBoxDst(_BoxMin, _BoxMax, origin, 1.0/dir);
    // return rayToBox.y == 0.0;
    float2 range = float2(rayToBox.x, rayToBox.x + rayToBox.y);

    float transmittance = 1.0;
    float totalDensity = 0.0;

    float step = (range.y - range.x) / _Steps;
    float t = range.x;

    for (int i=0; i<_Steps; i++) {
        float3 pos = origin + dir*t;
        float density = getDensity(pos);
        totalDensity += density * step;

        t += step;
    }

    transmittance = beer(totalDensity);
    return transmittance;
}

float4 frag(VaryingsDefault i): SV_Target {
    float4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoordStereo);

    float4 worldPos = GetWorldSpacePosition(depth, i.texcoord);
    float3 origin = _WorldSpaceCameraPos;
    float3 dir = normalize(worldPos.xyz - origin);
    float3 invDir = 1.0 / dir;
    float depthEyeLinear = length(worldPos.xyz - _WorldSpaceCameraPos);
    float2 rayToBox = rayBoxDst(_BoxMin, _BoxMax, origin, invDir);

    bool hitBox = rayToBox.y > 0 && rayToBox.x < depthEyeLinear;
    float2 range = float2(rayToBox.x, min(rayToBox.x + rayToBox.y, depthEyeLinear));

    float cosA = dot(dir, _LightDir);

    float transmittance = 1.0;
    float lightEnergy = 0.0;
    if (hitBox) {
        // Ray Marching
        float step = (range.y - range.x) / _Steps;
        float t = range.x;

        for (int i=0; i<_Steps; i++) {
            float3 pos = origin + dir*t;
            float density = getDensity(pos);

            float lightTransmittance = lightMarch(pos);
            return lightTransmittance;
            lightEnergy += _LightIntensity * lightTransmittance * density * step * transmittance * hg(cosA, 0.2);
            transmittance *= beer(density * step);

            t += step;
        }
    }


    // return cosA;
    return baseColor * transmittance + (1-transmittance) * _LightColor * lightEnergy;
}