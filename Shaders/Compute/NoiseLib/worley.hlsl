#ifndef _WORLEY_NOISE
#define _WORLEY_NOISE

#include "hash.hlsl"

float Worley2D(float2 p, float frequency = 1.0, bool isTiling = false) {
    p *= frequency;
    float2 i = floor(p);
    float2 f = frac(p);

    float minD = 2.0;
    for (int x=-1; x<=1; x++)
        for (int y=-1; y<=1; y++) {
            float2 t;
            if (!isTiling)
                t = 0.5 + 0.5 * hash22(i + float2(x, y));
            else 
                t = 0.5 + 0.5 * hash22(i + float2(x, y), frequency);
            float d = length(t + float2(x, y) - f);
            minD = min(minD, d);
        }
    return min(minD, 1.0);
}

float Worley3D(float3 p, float frequency = 1.0, bool isTiling = false) {
    p *= frequency;
    float3 i = floor(p);
    float3 f = frac(p);

    float minD = 2.0;
    for (int x=-1; x<=1; x++)
        for (int y=-1; y<=1; y++)
            for (int z=-1; z<=1; z++) {
                float3 t;
                if (!isTiling)
                    t = 0.5 + 0.5 * hash33(i + float3(x, y, z));
                else 
                    t = 0.5 + 0.5 * hash33(i + float3(x, y, z), frequency);
                float d = length(t + float3(x, y, z) - f);
                minD = min(minD, d);
            }
    return min(minD, 1.0);
}

#endif