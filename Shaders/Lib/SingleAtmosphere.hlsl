#ifndef SINGLE_ATMOSPHERE
#define SINGLE_ATMOSPHERE

#include "common.hlsl"

float2 lightSampling(float3 pos, in DirectionalLight light, in Planet planet) {
    const int stepCount = 8;

    float2 opticalDepth = 0.0;

    float3 ori = pos;
    float3 dir = -light.dir;

    // 被地球遮挡则直接返回
    float3 planetIntersection = ShpereIntersect(ori, dir, planet.center, planet.radius);
    if (planetIntersection.z && planetIntersection.x > 0) return 1e8;

    float3 intersection = ShpereIntersect(ori, dir, planet.center, planet.globalAtmosphereHeight());
    if (intersection.y <= 0 || !intersection.z) return 0.0;
    intersection.x = max(0, intersection.x);

    float step = (intersection.y - intersection.x) / stepCount;
    for (float t=intersection.x; t<intersection.y; t+=step) {
        float3 samplePosition = ori + (t + step/2.0) * dir;
        float height = length(samplePosition - planet.center) - planet.radius;

        opticalDepth += exp(-(height.xx/planet.densityScaleHeight)) * step;
    }

    return opticalDepth;
}

void ApplyPhaseFunction(inout float3 scatterR, inout float3 scatterM, float cosAngle, in Planet planet)
{
	// r
	float phase = (3.0 / (16.0 * PI)) * (1 + (cosAngle * cosAngle));
	scatterR *= phase;

	// m
	float g = planet.mieG;
	float g2 = g * g;
	phase = (1.0 / (4.0 * PI)) * ((3.0 * (1.0 - g2)) / (2.0 * (2.0 + g2))) * ((1 + cosAngle * cosAngle) / (pow((1 + g2 - 2 * g * cosAngle), 3.0 / 2.0)));
	scatterM *= phase;
}

float3 IntegrateInscattering(float3 ori, float3 dir, in Planet planet, in DirectionalLight light) {
    const int stepCount = 32;

    float3 planetIntersection = ShpereIntersect(ori, dir, planet.center, planet.radius);
    float3 intersection = ShpereIntersect(ori, dir, planet.center, planet.globalAtmosphereHeight());

    // 不经过大气层
    // if (!planetIntersection.z) return baseColor;

    // 大气步进起止点
    float2 range;
    range.x = max(0.0, intersection.x);
    range.y = intersection.y;

    if (planetIntersection.z && planetIntersection.x>0.0) range.y = planetIntersection.x;

    float step = (range.y - range.x) / stepCount;
    float3 totalR = 0.0;
    float3 totalM = 0.0;

    float2 DPA = 0.0;
    float h0 = length(ori + (step/4.0) * dir - planet.center) - planet.radius;
    float2 density0 = exp(-(h0.xx/planet.densityScaleHeight));
    DPA += density0 * (step/2.0);
    
    for (float t=range.x; t<range.y; t+=step) {
        float3 pos = ori + (t + step/2.0) * dir;
        float height = length(pos - planet.center) - planet.radius;
        float2 localDensity = exp(-(height.xx/planet.densityScaleHeight));

        float2 DSP = lightSampling(pos, light, planet);
        float2 opticalDepth = DSP + DPA;

        float3 extinction = exp(-(opticalDepth.x*planet.extinctionR + opticalDepth.y*planet.extinctionM));

        totalR += localDensity.x * extinction * step;
        totalM += localDensity.y * extinction * step;
        
        DPA += localDensity * step;
    }

    ApplyPhaseFunction(totalR, totalM, dot(dir, -light.dir), planet);
    float3 lightInscatter = light.intensity * light.color * 
                            (planet.scatteringR * totalR + planet.scatteringM * totalM);
    float3 lightExtinction = exp(-(DPA.x*planet.extinctionR + DPA.y*planet.extinctionM));
    
    if (planetIntersection.z && planetIntersection.x>0.0) lightInscatter += lightExtinction*planet.color;
    return lightInscatter;
}

#endif