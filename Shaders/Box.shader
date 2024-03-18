Shader "Custom/Box"
{
    Properties
    {
        _Width ("width", range(0.0, 0.1)) = 0.01
        _Color ("color", color) = (0.0, 0.0, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "Queue"="AlphaTest" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            float _Width;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 color = 0.0;

                if (i.uv.x < _Width || i.uv.x > 1 - _Width || i.uv.y < _Width || i.uv.y > 1 - _Width) {
                    color = _Color;
                }
                clip(color.a - 0.1);
                return _Color;
            }
            ENDCG
        }
    }
}
