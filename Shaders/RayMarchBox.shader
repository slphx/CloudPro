Shader "Hidden/PostProcessing/RayMarchBox"
{
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            HLSLPROGRAM
            // #pragma vertex VertDefault
            // #pragma fragment frag
            // #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
            // #include "RayMarchBox.hlsl"
            ENDHLSL
        }
    }
}