Shader "Unlit/Noise3DVisualize"
{
    Properties
    {
        _NoiseTex("Texture", 3D) = "white" {}
        _SampleSlice("Slice", Range(0.0, 1.0)) = 0.0
        _Intensity("Intensity", Range(0.1, 5.0)) = 1.0
        [Enum(all, 0, r, 1, g, 2, b, 3, a, 4)]_ShowPath("ShowPath", Int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            int _Resolution;
            sampler3D _NoiseTex;
            float4 _NoiseTex_ST;
            float _SampleSlice;
            float _Intensity;
            int _ShowPath;
    

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 col = tex3D(_NoiseTex, float3(i.uv, _SampleSlice)) * _Intensity;
                col.w = pow(col.w, 2.2);
                // col = 0;
                if (_ShowPath == 1) col = col.r;
                if (_ShowPath == 2) col = col.g;
                if (_ShowPath == 3) col = col.b;
                if (_ShowPath == 4) col = col.a;
                col.a = 1.0;

                return col;
            }
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            Cull Off
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
            #include "UnityCG.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG

        }
    }
}