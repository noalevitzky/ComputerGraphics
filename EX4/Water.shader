Shader "CG/Water"
{
    Properties
    {
        _CubeMap("Reflection Cube Map", Cube) = "" {}
        _NoiseScale("Texture Scale", Range(1, 100)) = 10 
        _TimeScale("Time Scale", Range(0.1, 5)) = 3 
        _BumpScale("Bump Scale", Range(0, 0.5)) = 0.05
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"
                #include "CGRandom.cginc"

                #define DELTA 0.01

                // Declare used properties
                uniform samplerCUBE _CubeMap;
                uniform float _NoiseScale;
                uniform float _TimeScale;
                uniform float _BumpScale;

                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float2 uv       : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos      : SV_POSITION;
                    float2 uv       : TEXCOORD1;
                    float3 normal   : TEXCOORD2;
                    float4 worldPos : TEXCOORD3;
                    float4 tangent  : TEXCOORD4;
                };

                // Returns the value of a noise function simulating water, at coordinates uv and time t
                float waterNoise(float2 uv, float t)
                {
                    // Your implementation
                    return (perlin3d(float3(0.5*uv.x, 0.5*uv.y, 0.5*t)) + 0.5*perlin3d(float3(uv.x, uv.y, t)) +
                            0.2*perlin3d(float3(2*uv.x, 2*uv.y, 3*t)));
                }

                // Returns the world-space bump-mapped normal for the given bumpMapData and time t
                float3 getWaterBumpMappedNormal(bumpMapData i, float t)
                {
                    float3 output;
                    float f_p = waterNoise(i.uv, t) * 0.5 + 0.5;
                    float f_u = ((waterNoise(float2(i.uv.x + i.du, i.uv.y), t) * 0.5 + 0.5) - f_p) / i.du;
                    float f_v = ((waterNoise(float2(i.uv.x, i.uv.y + i.dv), t) * 0.5 + 0.5) - f_p) / i.dv;
                    float3 n_h = normalize(float3(-i.bumpScale * f_u, -i.bumpScale * f_v, 1));

                    float3 n = i.normal;
                    float3 t_tag = i.tangent;
                    float3 b = cross(t_tag, n);

                    output = (t_tag * n_h.x) + (n * n_h.z) + (b * n_h.y);
                    return output;
                }


                v2f vert (appdata input)
                {
                    v2f output;
                    output.normal = normalize(mul(unity_ObjectToWorld, input.normal));
                    output.tangent = normalize(mul(unity_ObjectToWorld, input.tangent));
                    output.uv = input.uv * _NoiseScale;

                    float h = waterNoise(output.uv, _Time.y * _TimeScale) * _BumpScale;
                    output.pos = UnityObjectToClipPos(input.vertex + (h * output.normal));
                    output.worldPos = mul(unity_ObjectToWorld, input.vertex + (h * output.normal));
                    
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    bumpMapData i;
                    i.normal = input.normal;
                    i.tangent = input.tangent;
                    i.uv = input.uv;
                    i.du = DELTA;
                    i.dv = DELTA;
                    i.bumpScale = _BumpScale;
                    
                    float3 newNormal = getWaterBumpMappedNormal(i, _Time.y * _TimeScale);

                    float3 v = normalize(_WorldSpaceCameraPos - input.worldPos);
                    float3 r = 2 * (dot(v, newNormal)) * newNormal - v;
                    half4 ReflectedColor = texCUBE(_CubeMap, r);
                    return (1 - max(0, dot(newNormal, v)) + 0.2) * ReflectedColor;
                }

            ENDCG
        }
    }
}
