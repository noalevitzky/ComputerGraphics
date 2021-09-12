void updateBestHit(inout RayHit bestHit, float3 p, float t, float3 n, Material m){
    bestHit.position = p; // Spatial position of the hit point
    bestHit.distance = t; // Distance t from the ray origin
    bestHit.normal = n; // Normal of the intersected surface at the hit point
    bestHit.material = m; // Material of the intersected surface
}

// Checks for an intersection between a ray and a sphere
// The sphere center is given by sphere.xyz and its radius is sphere.w
void intersectSphere(Ray ray, inout RayHit bestHit, Material material, float4 sphere)
{
    float A = 1;
    float B = 2 * dot((ray.origin - sphere.xyz), ray.direction);
    float C = dot((ray.origin - sphere.xyz), (ray.origin - sphere.xyz)) - pow(sphere.w, 2); 
    
    float D = pow(B, 2) - (4 * A * C);
    

    // ray missed the sphere
    if (D < 0) {
        return;
    }


    // ray intersect once
    else if (D == 0) {
        float t = -B / (2 * A);
        if (t < bestHit.distance && t > 0) {
            float3 p = ray.origin + (ray.direction * t);
            float3 n = normalize(p - sphere.xyz);
            updateBestHit(bestHit, ray.origin + (ray.direction * t), t, n, material);  
            return;
        }
    }

    // ray has 2 intersections
    else if (D > 0) {
        float t0 = (-B + sqrt(pow(B, 2) - 4 * A * C)) / (2 * A);
        float t1 = (-B - sqrt(pow(B, 2) - 4 * A * C)) / (2 * A);
        float t_min = min(t0, t1);
        float t_max = max(t0, t1);

        if (t_max <= 0) {
            return;
        }

        float t = (t_min > 0) ? t_min : t_max;
        if (t < bestHit.distance) {
            float3 p = ray.origin + (ray.direction * t);
            float3 n = normalize(p - sphere.xyz);
            updateBestHit(bestHit, ray.origin + (ray.direction * t), t, n, material);         
        }
    }
    return;
}

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
void intersectPlane(Ray ray, inout RayHit bestHit, Material material, float3 c, float3 n)
{
    if (dot(ray.direction, n) == 0) {
        return;
    }
    float t = -dot(ray.origin - c, n) / dot(ray.direction, n);
    
    if (t < 0) {
        return;
    }
    if (t < bestHit.distance) {
        updateBestHit(bestHit, ray.origin + (ray.direction * t), t, n, material);         
    }
    return;
}

bool isM1(float2 p2) {

        if ((p2.x < 0.5 && p2.y < 0.5) || (p2.x >= 0.5 && p2.y >= 0.5)) {
            return true;
        }
        return false;
}

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
// The material returned is either m1 or m2 in a way that creates a checkerboard pattern 
void intersectPlaneCheckered(Ray ray, inout RayHit bestHit, Material m1, Material m2, float3 c, float3 n)
{
    // Your implementation
    if (dot(ray.direction, n) == 0) {
        return;
    }
    float t = -dot(ray.origin - c, n) / dot(ray.direction, n);
    
    if (t < 0) {
        return;
    }

    if (t < bestHit.distance) {
        float3 p = ray.origin + (ray.direction * t);
        Material m;
        float2 p_temp;

        if (dot(n, float3(0, 0, 1)) == 1){
            p_temp = frac(float2(p.x, p.y));
        }
        else if (dot(n, float3(0, 1, 0)) == 1){
            p_temp = frac(float2(p.x, p.z));
        }
        else {
            p_temp = frac(float2(p.y, p.z));
        }

        if (isM1(p_temp)) {
            m = m1;
        }
        else {
            m = m2;
        }

        updateBestHit(bestHit, p, t, n, m);   
    }
}


// Checks for an intersection between a ray and a triangle
// The triangle is defined by points a, b, c
void intersectTriangle(Ray ray, inout RayHit bestHit, Material material, float3 a, float3 b, float3 c)
{
    // Your implementation
    // save previous best hit, and check if ray intersects with plane
    // float prev_distance = bestHit.distance;
    float3 n = normalize(cross((a-c), (b-c)));
    RayHit testRayHit = CreateRayHit();
    intersectPlane(ray, testRayHit, material, a, n);
    // no intersection with plane
    if (isinf(testRayHit.distance)) {
        return;
    }
    // else, check intersection with Triangle
    bool condition1 = (dot(cross((b - a), (testRayHit.position - a)), n) >= 0);
    bool condition2 = (dot(cross((c - b), (testRayHit.position - b)), n) >= 0);
    bool condition3 = (dot(cross((a - c), (testRayHit.position - c)), n) >= 0);
    bool condition4 = testRayHit.distance < bestHit.distance;

    // ray intersects with triangle
    if (condition1 && condition2 && condition3 && condition4) {
        updateBestHit(bestHit, testRayHit.position, testRayHit.distance, testRayHit.normal, testRayHit.material);
    }
}


// Checks for an intersection between a ray and a 2D circle
// The circle center is given by circle.xyz, its radius is circle.w and its orientation vector is n 
void intersectCircle(Ray ray, inout RayHit bestHit, Material material, float4 circle, float3 n)
{
    RayHit testRayHit = CreateRayHit();
    intersectPlane(ray, testRayHit, material, circle.xyz ,n);

    // no intersection with plane
    if (isinf(testRayHit.distance)) {
        return;
    }
    // else, check intersection with circle
    bool condition1 = (length(circle.xyz - testRayHit.position) <= circle.w);
    bool condition2 = testRayHit.distance < bestHit.distance;
    bool condition3 = dot(n, ray.direction) < 0;

    // ray intersects with circle
    if (condition1 && condition2 && condition3) {
        updateBestHit(bestHit, testRayHit.position, testRayHit.distance, testRayHit.normal, testRayHit.material);
    }
}


// Checks for an intersection between a ray and a cylinder aligned with the Y axis
// The cylinder center is given by cylinder.xyz, its radius is cylinder.w and its height is h
void intersectCylinderY(Ray ray, inout RayHit bestHit, Material material, float4 cylinder, float h)
{
    //rename constants
   float o_x = ray.origin.x;
   float o_z = ray.origin.z;
   float d_x = ray.direction.x;
   float d_z = ray.direction.z;
   float c_x = cylinder.x;
   float c_z = cylinder.z;
   float r = cylinder.w;

   //calc coefficients
   float A = pow(d_x, 2) + pow(d_z, 2);
   float B = (2 * o_x * d_x) + (2 * o_z * d_z) - (2 * d_x * c_x) - (2 * d_z * c_z);
   float C = pow(o_x, 2) + pow(o_z, 2) - (2 * o_x * c_x) -(2 * o_z * c_z) + pow(c_x, 2) + pow(c_z, 2) - pow(r, 2);

   float D = pow(B, 2) - (4 * A * C);
    
    // ray missed the cylinder
    if (D < 0) {
        return;
    }

    // ray intersect once
    else if (D == 0) {
        float t = -B / (2 * A);

        float3 p = ray.origin + (ray.direction * t);
        if ((t > 0) && (t < bestHit.distance) && (p.y <= cylinder.y + h / 2) && (p.y >= cylinder.y - h / 2)) {
            updateBestHit(bestHit, p, t, normalize(p - float3(cylinder.x, p.y, cylinder.z)), material);      
        }
        return;
    }
    // ray has 2 intersections
    else if (D > 0) {
        float t0 = (-B + sqrt(pow(B, 2) - 4 * A * C)) / (2 * A);
        float t1 = (-B - sqrt(pow(B, 2) - 4 * A * C)) / (2 * A);
        float t_min = min(t0, t1);
        float t_max = max(t0, t1);

        if (t_max <= 0) {
            return;
        }

        // check both points
        if (t_min > 0){
            float t = t_min;
            float3 p = ray.origin + (ray.direction * t);
            if ((t > 0) && (t < bestHit.distance) && (p.y <= cylinder.y + h / 2) && (p.y >= cylinder.y - h / 2)) {
                // t_min intersect
                updateBestHit(bestHit, p, t, normalize(p - float3(cylinder.x, p.y, cylinder.z)), material);  
                return;
            }
            // t_min do not intersect, continue checking t_max below
        }

        // check t_max only
        float t = t_max;
        float3 p = ray.origin + (ray.direction * t);
        if ((t > 0) && (t < bestHit.distance) && (p.y <= cylinder.y + h / 2) && (p.y >= cylinder.y - h / 2)) {
            updateBestHit(bestHit, p, t, normalize(p - float3(cylinder.x, p.y, cylinder.z)), material);
        }
        return;
    }
}
