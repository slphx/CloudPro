struct a2v
{
    float4 pos : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 pos : SV_POSITION;
};

int _Resolution;
sampler3D _NoiseTex;
float4 _NoiseTex_ST;
float _SampleSlice;

v2f vert (a2v v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.pos);
    o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
    return o;
}

float4 frag (v2f i) : SV_Target
{
    float4 col = tex3D(_NoiseTex, float3(i.uv, _SampleSlice));
    return col;
}