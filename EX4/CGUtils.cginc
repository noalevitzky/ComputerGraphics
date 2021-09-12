#ifndef CG_UTILS_INCLUDED
#define CG_UTILS_INCLUDED

#define PI 3.141592653

// A struct containing all the data needed for bump-mapping
struct bumpMapData
{ 
    float3 normal;       // Mesh surface normal at the point
    float3 tangent;      // Mesh surface tangent at the point
    float2 uv;           // UV coordinates of the point
    sampler2D heightMap; // Heightmap texture to use for bump mapping
    float du;            // Increment size for u partial derivative approximation
    float dv;            // Increment size for v partial derivative approximation
    float bumpScale;     // Bump scaling factor
};


// Receives pos in 3D cartesian coordinates (x, y, z)
// Returns UV coordinates corresponding to pos using spherical texture mapping
float2 getSphericalUV(float3 pos)
{
    float r = sqrt(pow(pos.x, 2) + pow(pos.y, 2) + pow(pos.z, 2));
    float teta = atan2(pos.z, pos.x);
    float phi = acos(pos.y / r);
    float u = 0.5 + (teta / (2 * PI));
    float v = 1 - (phi / PI);
    return float2(u, v);
}

// Implements an adjusted version of the Blinn-Phong lighting model
fixed4 blinnPhong(float3 n, float3 v, float3 l, float shininess, fixed4 albedo, fixed4 specularity, float ambientIntensity)
{
    float3 h = normalize(l + v);
    fixed4 ambient = ambientIntensity * albedo;
    fixed4 diffuse = max(0, dot(n, l)) * albedo;
    fixed4 specular = pow(max(0, dot(n, h)), shininess) * specularity;

    return ambient + diffuse + specular;
}

// Returns the world-space bump-mapped normal for the given bumpMapData
float3 getBumpMappedNormal(bumpMapData i)
{
    float3 output;

    float f_u = (tex2D(i.heightMap, float2(i.uv.x + i.du, i.uv.y)).x - tex2D(i.heightMap, i.uv).x) / i.du;
    float f_v = (tex2D(i.heightMap, float2(i.uv.x, i.uv.y + i.dv)).x - tex2D(i.heightMap, i.uv).x) / i.dv;
    float3 n_h = normalize(float3(-i.bumpScale * f_u, -i.bumpScale * f_v, 1));

    float3 n = i.normal;
    float3 t = i.tangent;
    float3 b = cross(t, n);

    output = (t * n_h.x) + (n * n_h.z) + (b * n_h.y);
    return output;
}


#endif // CG_UTILS_INCLUDED
