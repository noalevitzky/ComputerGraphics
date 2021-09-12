#ifndef CG_RANDOM_INCLUDED
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
#define CG_RANDOM_INCLUDED

// Returns a psuedo-random float between -1 and 1 for a given float c
float random(float c)
{
    return -1.0 + 2.0 * frac(43758.5453123 * sin(c));
}

// Returns a psuedo-random float2 with componenets between -1 and 1 for a given float2 c 
float2 random2(float2 c)
{
    c = float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5, 183.3)));

    float2 v = -1.0 + 2.0 * frac(43758.5453123 * sin(c));
    return v;
}

// Returns a psuedo-random float3 with componenets between -1 and 1 for a given float3 c 
float3 random3(float3 c)
{
    float j = 4096.0 * sin(dot(c, float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
    r = -1.0 + 2.0 * r;
    return r.yzx;
}

// Interpolates a given array v of 4 float2 values using bicubic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
//
// [0]=====o==[1]
//         |
//         t
//         |
// [2]=====o==[3]
//
float bicubicInterpolation(float v[4], float2 t)
{
    float2 u = t * t * (3.0 - 2.0 * t); // Cubic interpolation

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 4 float2 values using biquintic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
float biquinticInterpolation(float v[4], float2 t)
{
    // Your implementation
    float2 u = t * t * t * (6.0 * t * t - 15.0 * t + 10.0);

    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 8 float3 values using triquintic interpolation
// at the given ratio t (a float3 with components between 0 and 1)
float triquinticInterpolation(float v[8], float3 t)
{
    float3 u = t * t * t * (6.0 * t * t - 15.0 * t + 10.0);
    
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);
    float x3 = lerp(v[4], v[5], u.x);
    float x4 = lerp(v[6], v[7], u.x);

    float y1 = lerp(x1, x2, u.y);
    float y2 = lerp(x3, x4, u.y);

    return lerp(y1, y2, u.z);

}

// Returns the value of a 2D value noise function at the given coordinates c
float value2d(float2 c)
{
    // Your implementation
    float topLeft = random2(floor(c) + float2(0, 1));
    float topRight = random2(floor(c) + float2(1, 1));
    float bottomLeft = random2(floor(c));
    float bottomRight = random2(floor(c) + float2(1, 0));
    
    float v[4] = {bottomLeft, bottomRight, topLeft, topRight};
    return bicubicInterpolation(v, frac(c));
}

// Returns the value of a 2D Perlin noise function at the given coordinates c
float perlin2d(float2 c)
{
    // Your implementation
    float2 topLeft = floor(c) + float2(0, 1);
    float2 topRight = floor(c) + float2(1, 1);
    float2 bottomLeft = floor(c);
    float2 bottomRight = floor(c) + float2(1, 0);

    float2 topLeftGrad = random2(floor(c) + float2(0, 1));
    float2 topRightGrad = random2(floor(c) + float2(1, 1));
    float2 bottomLeftGrad = random2(floor(c));
    float2 bottomRightGrad = random2(floor(c) + float2(1, 0));

    float2 topLeftDist = c - topLeft;
    float2 topRightDist = c - topRight;
    float2 bottomLeftDist = c - bottomLeft;
    float2 bottomRightDist = c - bottomRight;

    float topLeftDot = dot(topLeftGrad, topLeftDist);
    float topRightDot = dot(topRightGrad, topRightDist);
    float bottomLeftDot = dot(bottomLeftGrad, bottomLeftDist);
    float bottomRightDot = dot(bottomRightGrad, bottomRightDist);

    float v[4] = {bottomLeftDot, bottomRightDot, topLeftDot, topRightDot};
    return biquinticInterpolation(v, frac(c));
}

// Returns the value of a 3D Perlin noise function at the given coordinates c
float perlin3d(float3 c)
{   
    float3 frontTopLeft = floor(c) + float3(0, 1, 0);
    float3 frontTopRight = floor(c) + float3(1, 1, 0);
    float3 frontBottomLeft = floor(c);
    float3 frontBottomRight = floor(c) + float3(1, 0, 0);
    float3 backTopLeft = floor(c) + float3(0, 1, 1);
    float3 backTopRight = floor(c) + float3(1, 1, 1);
    float3 backBottomLeft = floor(c) + float3(0, 0, 1);
    float3 backBottomRight = floor(c) + float3(1, 0, 1);

    float3 frontTopLeftGrad = random3(floor(c) + float3(0, 1, 0));
    float3 frontTopRightGrad = random3(floor(c) + float3(1, 1, 0));
    float3 frontBottomLeftGrad = random3(floor(c));
    float3 frontBottomRightGrad = random3(floor(c) + float3(1, 0, 0));
    float3 backTopLeftGrad = random3(floor(c) + float3(0, 1, 1));
    float3 backTopRightGrad = random3(floor(c) + float3(1, 1, 1));
    float3 backBottomLeftGrad = random3(floor(c) + float3(0, 0, 1));
    float3 backBottomRightGrad = random3(floor(c) + float3(1, 0, 1));

    float3 frontTopLeftDist = c - frontTopLeft;
    float3 fronTopRightDist = c - frontTopRight;
    float3 frontBottomLeftDist = c - frontBottomLeft;
    float3 frontBottomRightDist = c - frontBottomRight;
    float3 backTopLeftDist = c - backTopLeft;
    float3 backTopRightDist = c - backTopRight;
    float3 backBottomLeftDist = c - backBottomLeft;
    float3 backBottomRightDist = c - backBottomRight;

    float frontTopLeftDot = dot(frontTopLeftGrad, frontTopLeftDist);
    float frontTopRightDot = dot(frontTopRightGrad, fronTopRightDist);
    float frontBottomLeftDot = dot(frontBottomLeftGrad, frontBottomLeftDist);
    float frontBottomRightDot = dot(frontBottomRightGrad, frontBottomRightDist);
    float backTopLeftDot = dot(backTopLeftGrad, backTopLeftDist);
    float backTopRightDot = dot(backTopRightGrad, backTopRightDist);
    float backBottomLeftDot = dot(backBottomLeftGrad, backBottomLeftDist);
    float backBottomRightDot = dot(backBottomRightGrad, backBottomRightDist);

    float v[8] = {frontBottomLeftDot, frontBottomRightDot, frontTopLeftDot, frontTopRightDot,
                    backBottomLeftDot, backBottomRightDot, backTopLeftDot, backTopRightDot};
    return triquinticInterpolation(v, frac(c));
    
}


#endif // CG_RANDOM_INCLUDED
