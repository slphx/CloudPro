#include "lib/common.hlsl"

struct appdata {
    float4 vertex: POSITION;
    float2 uv: TEXCOORD0;
};

struct v2f {
    float4 vertex: SV_POSITION;
    float2 uv: TEXCOORD0;
};

// vertex shader
v2f vert(appdata v) {
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;
    
    return o;
}



uniform float4x4 _InverseProjectionMatrix;
uniform float4x4 _InverseViewMatrix;

sampler2D _CameraDepthTexture;
float4 _CameraDepthTexture_ST;
sampler2D _MainTex;
float4 _MainTex_ST;

// cloud
float4 _Color;
float3 _BoxMin;
float3 _BoxMax;
float2 _Scale;
float3 _Offset;
float _DensityThreshold;
float _DensityMultiplier;
float _LightCloudCoef;
float _CloudAmbient;

// light
float3 _LightDir;
float _LightIntensity;
float4 _LightColor;

sampler3D _NoiseTex;
float4 _NoiseTex_ST;


float getDensity(float3 pos) {
    // float3 uvw = (pos - _BoxMin) / (_BoxMax - _BoxMin);
    float3 uvw = pos * _Scale.x + _Offset * _Scale.y;

    // float density = tex3D(_NoiseTex, uvw);
    float density = tex3Dlod(_NoiseTex, float4(uvw, 0));
    // float density = _Noise.SampleLevel(sampler_Noise, uvw, 0);

    return max(0.0, density - _DensityThreshold) * _DensityMultiplier;
}

float beer(float od) {
    return exp(-od);
}

float powder_sugar_effect(float d) {
    return 2.0 * exp(-d) * (1.0 - exp(-d*2.0));
}

float hg(float a, float g) 
{
  float g2 = g * g;
  return (1 - g2) / (4 * PI * pow(1 + g2 - 2 * g * (a), 1.5));
}

// float phase(float a) 
// {
//     float blend = 0.5;
//     float hgBlend = hg(a, _phaseParams.x) * (1 - blend) + hg(a, -_phaseParams.y) * blend;
//     return _phaseParams.z + hgBlend * _phaseParams.w;
// }

float lightMarch(float3 pos) {
    int stepCount = 16;

    float3 ori = pos;
    float3 dir = -_LightDir;
    float2 rayToBox = rayBoxDst(_BoxMin, _BoxMax, ori, 1.0/dir);

    float2 range = float2(rayToBox.x, rayToBox.x + rayToBox.y);

    float opticalDepth = 0.0;

    float step = (range.y - range.x) / stepCount + 0.001;

    for (float t=range.x; t<range.y; t+=step) {
        float3 pos = ori + (t + step/2.0) * dir;
        float localDensity = getDensity(pos);

        opticalDepth += localDensity * step;
    }

    return opticalDepth;
}

float4 frag(v2f i): SV_Target {
    float4 baseColor = tex2D(_MainTex, i.uv);
    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);

    float3 pos = GetWorldSpacePosition(i.uv, depth, _InverseProjectionMatrix, _InverseViewMatrix);
    float3 ori = _WorldSpaceCameraPos;
    float3 dir = pos - ori;
    float depthLinear = length(dir);
    dir = normalize(dir);

    float2 rayToBox = rayBoxDst(_BoxMin, _BoxMax, ori, 1.0/dir);

    bool hitBox = rayToBox.y > 0 && rayToBox.x < depthLinear;
    float2 range = float2(rayToBox.x, rayToBox.x + rayToBox.y);
    range.y = min(range.y, depthLinear);
    
    float cosA = dot(dir, -_LightDir);

    float transmittance = 1.0;
    float lightAccum = 0.0;
    if (hitBox) {
        // Ray Marching
        int stepCount = 32;
        float step = (range.y - range.x) / stepCount + 0.001;

        float opticalDepth = 0.0;
        for (float t=range.x; t<range.y; t+=step) {
            float3 pos = ori + (t + step/2.0) * dir;
            float localDensity = getDensity(pos);

            float lightOpticalDepth = lightMarch(pos);
            lightAccum += beer(lightOpticalDepth + opticalDepth) * localDensity * step;
            // lightEnergy += _LightIntensity * lightTransmittance * density * step * transmittance * hg(cosA, 0.2);
            // transmittance *= beer(density * step);
            // return 1.0;
            opticalDepth += localDensity * step;
        }
        transmittance = beer(opticalDepth);
        // return lightAccum;
    }

    float cloud = _LightColor * _LightIntensity * _LightCloudCoef * lightAccum + _CloudAmbient;
    cloud *= hg(cosA, 0.2);

    return baseColor * transmittance + cloud * (1 - transmittance);
}