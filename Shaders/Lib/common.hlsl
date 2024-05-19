#ifndef COMMON
#define COMMON

#include "structs.hlsl"

#define PI 3.141592653

float3 GetWorldSpacePosition(float2 uv, float depth, float4x4 _InverseProjectionMatrix, float4x4 _InverseViewMatrix) {
    float4 viewSpacePosition = mul(_InverseProjectionMatrix, float4(-1.0 + 2.0*uv, depth, 1.0));
    viewSpacePosition /= viewSpacePosition.w;

    float3 worldSpacePosition = mul(_InverseViewMatrix, viewSpacePosition).xyz;
    return worldSpacePosition;
}

// 当无交点时，z 分量返回 0 (通常情况返回 1)
float3 SphereIntersect(float3 ori, float3 dir, float3 center, float radius) {
    float3 PO = center - ori;
    float t = dot(PO, dir);
    float ht2 = radius * radius - dot(PO, PO) + t * t;

    if (ht2 < 0) return 0.0;

    float ht = sqrt(ht2);
    return float3(t - ht, t + ht, 1.0);
}

float2 SphericalShellIntersect(float3 ori, float3 dir, float center, float innerR, float outerR) {
    float3 intersectionInner = SphereIntersect(ori, dir, center, innerR);
    float3 intersectionOuter = SphereIntersect(ori, dir, center, outerR);

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
    return range;
}

// 返回距离该点最近距离的取值 t 与该最近距离
float2 PointIntersect(float3 ori, float3 dir, float3 p) {
    float3 PO = p - ori;
    float t = dot(PO, dir);
    float dist = sqrt(dot(PO, PO) - t*t);
    return (t, dist);
}

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



#endif