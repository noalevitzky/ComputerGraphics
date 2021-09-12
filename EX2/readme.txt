205970783 noa.levitzky
205676638 noa.weiss1

Part 1 - question 6:
When we implemented the CalculateNormals method, we used the normalized average direction of the surface normals per vertex. This caused a nice color gradient that looks smooth.
When implementing the MakeFlatShaded method, we created copies of each vertex- 1 per surface it is a part of, and set each unique vertex' normal to the surface normal it is a part of. 
Since each vertex is now part of only 1 surface, all vertices of the same surface will have exactly the same normal value (and there is no need to calculate normals average, because there is only 1 normal).
Thus, when interpolating the vertices normals to calculate the normal (color) for each point on the surface, we will get that all points on the same surface get the same color - because the vertices normals are all identical.
Now, since each surface has a single color, it creates the affect of flat shading.