Shader "Custom/CloudBox"
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
            #include "CloudBox.hlsl"

            ENDCG
        }
    }
}