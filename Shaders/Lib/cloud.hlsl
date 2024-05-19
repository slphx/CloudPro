#ifndef CLOUD
#define CLOUD

#include "Lib/SingleAtmosphere.hlsl"

sampler3D _NoiseTex;
float4 _NoiseTex_ST;

sampler2D _CoverageTex;
float4 _CoverageTex_ST;

float remap(float a, float omin, float omax, float nmin, float nmax) {
    return nmin + (a - omin)/(omax - omin)*(nmax - nmin);
}

// para.x: 内半径 para.y: 外半径 para.z: 位置
float heightMap(float3 para, float p) {
    float r0 = para.x, r1 = para.y;
    float m = para.z;
    if (p < m - r1 || p > m + r1) return 0.0;
    if (p > m - r0 && p < m + r0) return 1.0;
    return remap(r1 - abs(p - m), 0.0, r1 - r0, 0.0, 1.0);
}

float getDensity(float3 pos, in Cloud cloud) {
    float3 paraR = float3(0.01, 0.04, 0.1);
    float3 paraG = float3(0.1, 0.3, 0.3);
    float3 paraB = float3(0.3, 0.5, 0.4);

    float height = (pos.y - cloud.heightMin)/(cloud.heightMax - cloud.heightMin);
    float height_map = heightMap(paraG, height);

    float3 uvw = pos * cloud.scale.x + cloud.offset * cloud.scale.y;

    float coverage = tex2Dlod(_CoverageTex, float4((uvw.xz+cloud.coverageOffset* cloud.scale.y)*0.2, 0, 0));
    // return coverage;

    // float4 tex = tex3Dlod(_NoiseTex, float4(uvw, 0));
    // uvw *= 10;
    float4 tex2;
    tex2 = tex3Dlod(_NoiseTex, float4(uvw, 0));
    tex2.w = pow(tex2.w, 2.2);
    float density = tex2.r;
    float fbmDensity = tex2.y * 0.625 + tex2.z * 0.25 + tex2.w * 0.125;

    // density = remap(density, -(1.0 - fbmDensity), 1.0, 0.0, 1.0);
    density += density * fbmDensity;

    density *= coverage * height_map;
    // density = remap(density, coverage, 1.0, 0.0, 1.0);

    return max(0.0, density - cloud.densityThreshold * 0.3) * cloud.densityMultiplier *0.2;
}

float beer(float od) {
    return exp(-od);
}

float powder_sugar_effect(float d) {
    return 2.0 * exp(-d) * (1.0 - exp(-d*2.0));
}

float hg(float a, float g) {
  float g2 = g * g;
  return (1 - g2) / (4 * PI * pow(1 + g2 - 2 * g * (a), 1.5));
}

float lightMarch(float3 pos, in Planet planet, in DirectionalLight light, in Cloud cloud) {
    int stepCount = 16;

    float3 ori = pos;
    float3 dir = -light.dir;

    // 寻找步进起止点
    float innerR = planet.radius + cloud.heightMin, outerR = planet.radius + cloud.heightMax;
    // float3 intersectionInner = SphereIntersect(ori, dir, planet.center, innerR);
    float3 intersectionOuter = SphereIntersect(ori, dir, planet.center, outerR);

    float2 range;
    // range.x = intersectionInner.x > 0 ? intersectionInner.x : intersectionInner.y;
    range.x = 0;
    range.y = intersectionOuter.y;
    range = max(0.0, range);

    float opticalDepth = 0.0;

    float step = (range.y - range.x) / stepCount + 0.001;

    for (float t=range.x; t<range.y; t+=step) {
        float3 pos = ori + (t + step/2.0) * dir;
        float localDensity = getDensity(pos, cloud);

        opticalDepth += localDensity * step;
    }

    return opticalDepth;
}

float4 SampleCloud(float3 ori, float3 dir, in Planet planet, in DirectionalLight light, in Cloud cloud) {
    
    // 寻找步进起止点
    float innerR = planet.radius + cloud.heightMin, outerR = planet.radius + cloud.heightMax;
    float3 intersectionInner = SphereIntersect(ori, dir, planet.center, innerR);
    float3 intersectionOuter = SphereIntersect(ori, dir, planet.center, outerR);

    float2 range;
    range.x = intersectionInner.x > 0 ? intersectionInner.x : intersectionInner.y;
    range.y = intersectionOuter.x > 0 ? intersectionOuter.x : intersectionOuter.y;
    range = max(0.0, range);
    if (range.x > range.y) {
        float t;
        t = range.x;
        range.x = range.y;
        range.y = t;
    }

    float3 planetIntersection = SphereIntersect(ori, dir, planet.center, planet.radius);
    range.y = planetIntersection.x > 0 ? min(range.y, planetIntersection.x) : range.y;

    // Ray Marching
    int stepCount = 128;
    float step = (range.y - range.x) / stepCount + 0.001;

    float opticalDepth = 0.0;
    float transmittance = 1.0;
    float lightAccum = 0.0;
    for (float t=range.x; t<range.y; t+=step) {
        float3 pos = ori + (t + step/2.0) * dir;

        float3 uvw = pos * cloud.scale.x + cloud.offset * cloud.scale.y;

        float localDensity = getDensity(pos, cloud);
        // return localDensity;

        float lightOpticalDepth = 0.0;
        if (localDensity > 0.0001) lightOpticalDepth = lightMarch(pos, planet, light, cloud);

        // return 0.00001* lightOpticalDepth;
        lightAccum += beer(lightOpticalDepth + opticalDepth) * localDensity * step;
        // lightEnergy += _LightIntensity * lightTransmittance * density * step * transmittance * hg(cosA, 0.2);
        // transmittance *= beer(density * step);
        // return 1.0;
        opticalDepth += localDensity * step;
    }
    transmittance = beer(opticalDepth);
    // return lightAccum;

    float cosA = dot(dir, -light.dir);

    float3 lightColor = IntegrateInscattering(ori, -light.dir, planet, light);
    // lightColor = float3(lightColor.x, light.color.yz * 0.1);
    // normalize(lightColor);
    // return float4(lightColor,1.0);
    float3 cloudColor = lightColor * light.intensity * cloud.lightCloudCoef * lightAccum + cloud.cloudAmbient;
    cloudColor *= hg(cosA, 0.2);

    return float4(cloudColor, transmittance);
}

#endif