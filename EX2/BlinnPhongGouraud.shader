Shader "CG/BlinnPhongGouraud"
{
    Properties
    {
        _DiffuseColor ("Diffuse Color", Color) = (0.14, 0.43, 0.84, 1)
        _SpecularColor ("Specular Color", Color) = (0.7, 0.7, 0.7, 1)
        _AmbientColor ("Ambient Color", Color) = (0.05, 0.13, 0.25, 1)
        _Shininess ("Shininess", Range(0.1, 50)) = 10
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" } 

            CGPROGRAM
                
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"

                // From UnityCG
                uniform fixed4 _LightColor0; 

                // Declare used properties
                uniform fixed4 _DiffuseColor;
                uniform fixed4 _SpecularColor;
                uniform fixed4 _AmbientColor;
                uniform float _Shininess;

                struct appdata
                { 
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    fixed4 color : COLOR0;
                    float4 normal : NORMAL;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex); // Transform input position to clip position
                    output.normal = normalize(mul(unity_ObjectToWorld, float4(input.normal, 0))); // Normalize the input normal

                    float4 inputWorldPos = mul(unity_ObjectToWorld, input.vertex);

                    float4 n = output.normal;
                    float4 l = normalize(float4(_WorldSpaceLightPos0.xyz, 0)); // Directional light
                    float4 v = normalize(float4(_WorldSpaceCameraPos, 0) - inputWorldPos);
                    float4 h = normalize((l + v) / length(l + v));
                  
                    fixed4 colorD = max(dot(l, n), 0) * _DiffuseColor * _LightColor0;
                    fixed4 colorS = pow(max(dot(n, h), 0), _Shininess) * _SpecularColor * _LightColor0;
                    fixed4 colorA = _AmbientColor * _LightColor0;

                    output.color = colorD + colorS + colorA;
                    return output;
                }


                fixed4 frag(v2f input) : SV_Target
                {
                   return input.color;
                }

            ENDCG
        }
    }
}
