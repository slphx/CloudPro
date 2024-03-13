#ifndef _PERLIN_NOISE
#define _PERLIN_NOISE

#include "hash.hlsl"

// Perlin Noise 输出范围(-1, 1)
float Perlin2D(float2 p, float frequency = 1.0, bool isTiling = false) {
    p *= frequency;
    float2 i = floor(p);
    float2 f = frac(p);
    // float2 u = f * f * (3.0 - 2.0 * f);
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);    

    float perlin = 0.0;
    if (!isTiling) {
        perlin = lerp(  lerp(dot(hash22(i + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
                            dot(hash22(i + float2(1.0, 0.0)), f - float2(1.0, 0.0)), u.x),
                        lerp(dot(hash22(i + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
                            dot(hash22(i + float2(1.0, 1.0)), f - float2(1.0, 1.0)), u.x),
                        u.y);
        
    } else {
        perlin = lerp(lerp(dot(hash22(i + float2(0.0, 0.0), frequency), f - float2(0.0, 0.0)),
                        dot(hash22(i + float2(1.0, 0.0), frequency), f - float2(1.0, 0.0)), u.x),
                    lerp(dot(hash22(i + float2(0.0, 1.0), frequency), f - float2(0.0, 1.0)),
                        dot(hash22(i + float2(1.0, 1.0), frequency), f - float2(1.0, 1.0)), u.x),
                    u.y);
    }

    return perlin;
}

// IQ 佬用微分实现 Perlin 的方法，性能上更优
// https://iquilezles.org/articles/gradientnoise/
float Perlin3D(float3 p, float frequency = 1.0, bool isTiling = false) {
    p *= frequency;
    float3 i = floor(p);
    float3 f = frac(p);

    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float3 ga, gb, gc, gd, ge, gf, gg, gh;
    if (!isTiling) {
        ga = -1.0 + 2.0 * hash33(i+float3(0.0,0.0,0.0));
        gb = -1.0 + 2.0 * hash33(i+float3(1.0,0.0,0.0));
        gc = -1.0 + 2.0 * hash33(i+float3(0.0,1.0,0.0));
        gd = -1.0 + 2.0 * hash33(i+float3(1.0,1.0,0.0));
        ge = -1.0 + 2.0 * hash33(i+float3(0.0,0.0,1.0));
        gf = -1.0 + 2.0 * hash33(i+float3(1.0,0.0,1.0));
        gg = -1.0 + 2.0 * hash33(i+float3(0.0,1.0,1.0));
        gh = -1.0 + 2.0 * hash33(i+float3(1.0,1.0,1.0));
    } else {
        ga = -1.0 + 2.0 * hash33(i+float3(0.0,0.0,0.0), frequency);
        gb = -1.0 + 2.0 * hash33(i+float3(1.0,0.0,0.0), frequency);
        gc = -1.0 + 2.0 * hash33(i+float3(0.0,1.0,0.0), frequency);
        gd = -1.0 + 2.0 * hash33(i+float3(1.0,1.0,0.0), frequency);
        ge = -1.0 + 2.0 * hash33(i+float3(0.0,0.0,1.0), frequency);
        gf = -1.0 + 2.0 * hash33(i+float3(1.0,0.0,1.0), frequency);
        gg = -1.0 + 2.0 * hash33(i+float3(0.0,1.0,1.0), frequency);
        gh = -1.0 + 2.0 * hash33(i+float3(1.0,1.0,1.0), frequency);
    }

    
    float va = dot(ga, f-float3(0.0,0.0,0.0));
    float vb = dot(gb, f-float3(1.0,0.0,0.0));
    float vc = dot(gc, f-float3(0.0,1.0,0.0));
    float vd = dot(gd, f-float3(1.0,1.0,0.0));
    float ve = dot(ge, f-float3(0.0,0.0,1.0));
    float vf = dot(gf, f-float3(1.0,0.0,1.0));
    float vg = dot(gg, f-float3(0.0,1.0,1.0));
    float vh = dot(gh, f-float3(1.0,1.0,1.0));

    float v = va + 
            u.x*(vb-va) + 
            u.y*(vc-va) + 
            u.z*(ve-va) + 
            u.x*u.y*(va-vb-vc+vd) + 
            u.y*u.z*(va-vc-ve+vg) + 
            u.z*u.x*(va-vb-ve+vf) + 
            u.x*u.y*u.z*(-va+vb+vc-vd+ve-vf-vg+vh);

    return v;
}

#endif