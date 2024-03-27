#include "lib/SingleAtmosphere.hlsl"

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


// matrixs
float4x4 _InverseViewMatrix;
float4x4 _InverseProjectionMatrix;

// texture
sampler2D _CameraDepthTexture;
float4 _CameraDepthTexture_ST;
sampler2D _MainTex;
float4 _MainTex_ST;

// light
float3 _LightDir;
float3 _LightColor;
float _LightIntensity;

// planet
float4 _PlanetColor;
float _PlanetRadius;
float _AtmosphereHeight;
float2 _DensityScaleHeight;
float3 _ScatteringR;
float3 _ScatteringM;
float3 _ExtinctionR;
float3 _ExtinctionM;
float _MieG;

// fragment shader
float4 frag(v2f i): SV_Target {
    float4 baseColor = tex2D(_MainTex, i.uv);
    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);

    float3 pos = GetWorldSpacePosition(i.uv, depth, _InverseProjectionMatrix, _InverseViewMatrix);
    float3 ori = _WorldSpaceCameraPos;
    float3 dir = pos - ori;
    float depthLinear = length(dir);
    dir = normalize(dir);

    // set planet
    Planet planet;
    planet.color = baseColor;
    planet.center = float3(0, -_PlanetRadius, 0);
    planet.radius = _PlanetRadius;
    planet.atmosphereHeight = _AtmosphereHeight;
    planet.densityScaleHeight = _DensityScaleHeight;
    planet.scatteringM = _ScatteringM;
    planet.scatteringR = _ScatteringR;
    planet.extinctionM = _ExtinctionM;
    planet.extinctionR = _ExtinctionR;
    planet.mieG = _MieG;

    // set light
    DirectionalLight light;
    light.dir = _LightDir;
    light.color = _LightColor;
    light.intensity = _LightIntensity;

    if (depth > 0) return baseColor;

    float3 inscattering = IntegrateInscattering(ori, dir, planet, light);

    // return baseColor;
    return float4(inscattering, 1.0);

}