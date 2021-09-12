// Implements an adjusted version of the Blinn-Phong lighting model
float3 blinnPhong(float3 n, float3 v, float3 l, float shininess, float3 albedo)
{
    float3 h = normalize((l + v) / 2);
    float3 diffuse = max(0, dot(n, l)) * albedo;
    float3 specular = pow(max(0, dot(n, h)), shininess) * 0.4;

    return diffuse + specular;
}

// Reflects the given ray from the given hit point
void reflectRay(inout Ray ray, RayHit hit)
{
    // Your implementation
    float3 v = -ray.direction;
    float3 n = hit.normal;
    float3 r = (2 * dot(v, n) * n) - v;
    ray.origin = hit.position + (EPS * n);
    ray.direction = normalize(r);
    ray.energy *= hit.material.specular; 
}

// Refracts the given ray from the given hit point
void refractRay(inout Ray ray, RayHit hit)
{
    // Your implementation
    
    float3 i = ray.direction;
    // basic case - ray enters the material
    float3 n = hit.normal;
    float mu1 = 1;
    float mu2 = hit.material.refractiveIndex;
    
    // check if ray exits the material
    if (dot(n, i) > 0) {
        n = -n;
        mu1 = hit.material.refractiveIndex;
        mu2 = 1;
    }
    
    float mu = mu1 / mu2;
    float c1 = abs(dot(n, i));
    float c2 = sqrt(1 - (pow(mu, 2) * (1 - pow(c1, 2))));
    float3 t = (mu * i) + (((mu * c1) - c2) * n);

    ray.origin = hit.position - (EPS * n);
    ray.direction = normalize(t);
    
}

// Samples the _SkyboxTexture at a given direction vector
float3 sampleSkybox(float3 direction)
{
    float theta = acos(direction.y) / -PI;
    float phi = atan2(direction.x, -direction.z) / -PI * 0.5f;
    return _SkyboxTexture.SampleLevel(sampler_SkyboxTexture, float2(phi, theta), 0).xyz;
}