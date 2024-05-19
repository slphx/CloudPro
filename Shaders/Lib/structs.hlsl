#ifndef STRUCTS
#define STRUCTS

struct Planet {
    float4 color;
    float3 center;
    float radius;
    float atmosphereHeight;
    float2 densityScaleHeight;
    float3 scatteringR;
    float3 scatteringM;
    float3 extinctionR;
    float3 extinctionM;
    float mieG;

    float globalAtmosphereHeight() {
        return radius + atmosphereHeight;
    }
};

struct DirectionalLight {
    float3 dir;
    float3 color;
    float intensity;
};

struct Cloud {
    float3 heightMin;
    float3 heightMax;
    float2 scale;
    float3 offset;
    float densityThreshold;
    float densityMultiplier;
    float lightCloudCoef;
    float cloudAmbient;
    float2 coverageOffset;
};

#endif