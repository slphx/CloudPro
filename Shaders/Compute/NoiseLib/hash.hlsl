#ifndef _HASH_NOISE
#define _HASH_NOISE

// 白噪声，输入为整数, 输出范围(-1, 1)
float hash11(float p) {
    p = frac(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return -1. + 2. * frac(p);
}

float hash11(float p, int f) {
    p = p - f * floor(p/f);
    p = frac(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return -1. + 2. * frac(p);
}

float hash21(float2 p) {
	float3 p3  = frac(float3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return -1 + 2. * frac((p3.x + p3.y) * p3.z);
}

float2 hash22(float2 p) {
	float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return -1. + 2. * frac((p3.xx + p3.yz) * p3.zy);
}

float2 hash22(float2 p, int f) {
    p = p - f * floor(p/f);
	float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return -1. + 2. * frac((p3.xx + p3.yz) * p3.zy);
}

float2 hash12(float p) {
	float3 p3 = frac(p * float3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 33.33);
    return -1. + 2. * frac((p3.xx + p3.yz) * p3.zy);
}

float hash31(float3 p3) {
	p3 = frac(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return -1. + 2. * frac((p3.x + p3.y) * p3.z);
}

float3 hash13(float p) {
   float3 p3 = frac(p * float3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return -1. + 2. * frac((p3.xxy+p3.yzz)*p3.zyx); 
}

float3 hash33(float3 p3) {
	p3 = frac(p3 * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return -1. + 2. * frac((p3.xxy + p3.yxx) * p3.zyx);
}

float3 hash33(float3 p3, int f) {
    p3 = p3 - f * floor(p3/f);
	p3 = frac(p3 * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return -1. + 2. * frac((p3.xxy + p3.yxx) * p3.zyx);
}

#endif