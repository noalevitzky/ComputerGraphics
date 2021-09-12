noa.weiss1 205676638
noa.levitzky 205970783

Web pages we used:


Studets we consulted with:
None

Q1:
Part 4 - checkerd plane:
First, we checked the checkerd plane's orientation - XY, YZ or XZ - by comparing the plane's normal to the
axis's normals. We took the relevant coordinates from the hitpoit accordingly (p.x || p.y || p.z).
Then, in order to determine the correct material (black or white), we implemented a helper function to
determine on which quadrant of the (1, 1) square the hit point's fracted parts hit. We used the frac() method in order
to do so, and compared the fracted parts of the hitpoint to all 4 ranges of possible sub-squares in the (1, 1) square. Then we updated
the hitpoint material accordingly - if the fractions point > 0.5 or < 0.5 for both x and y - the material is black. Otherwise, it is white.

Q2:
Part 5 - intersectCylinderY implementation: 
similar to the one of ray-plane intersection- in order to find the intersection between an infinite cylider and a ray, we need to meet 2 conditions:
1) the point is on the ray: ray(t) = o + dt
2) the point is on the cylinder: f(p_x, p_y, p_z) = (p_x - c_x)^2 + (p_z - c_z)^2 - r^2 = 0

we discovered that:
p_x = o_x + d_x * t
p_z = o_z + d_z * t
and placed those variables in the cylinder equation. after calculation, we got the A,B,C coefficients, calculated D and found if there are none, 1 or 2 intersections with the infinite cylinder.

for each intersection, we then checked if the intersection point is on the finite cylinder- by checking that the y value is between (c.y - h/2 < y < c.y + h/2).

in case of 2 intersections with the finite cylinder, we chose the closest one by the t value.


