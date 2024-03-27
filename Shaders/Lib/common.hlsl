#ifndef COMMON
#define COMMON

#include "structs.hlsl"

#define PI 3.1415926

float3 GetWorldSpacePosition(float2 uv, float depth, float4x4 _InverseProjectionMatrix, float4x4 _InverseViewMatrix) {
    float4 viewSpacePosition = mul(_InverseProjectionMatrix, float4(-1.0 + 2.0*uv, depth, 1.0));
    viewSpacePosition /= viewSpacePosition.w;

    float3 worldSpacePosition = mul(_InverseViewMatrix, viewSpacePosition).xyz;
    return worldSpacePosition;
}

// 当无交点时，z 分量返回 0 (通常情况返回 1)
float3 ShpereIntersect(float3 ori, float3 dir, float3 center, float radius) {
    float3 PO = center - ori;
    float t = dot(PO, dir);
    float ht2 = radius * radius - dot(PO, PO) + t * t;

    if (ht2 < 0) return 0.0;

    float ht = sqrt(ht2);
    return float3(t - ht, t + ht, 1.0);
}

// 返回距离该点最近距离的取值 t 与该最近距离
float2 PointIntersect(float3 ori, float3 dir, float3 p) {
    float3 PO = p - ori;
    float t = dot(PO, dir);
    float dist = sqrt(dot(PO, PO) - t*t);
    return (t, dist);
}



#endif