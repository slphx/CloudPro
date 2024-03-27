Shader "Custom/CloudSky"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "CloudSky.hlsl"

            ENDCG
        }
    }
}