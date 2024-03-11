Shader "Unlit/NoisePlane"
{
    Properties
    {
        _NoiseTex("Texture", 2D) = "white" {}
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
            #include "NoisePlane.hlsl"
            ENDCG
        }
    }
}
