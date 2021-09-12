using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class MeshData
{
    public List<Vector3> vertices; // The vertices of the mesh 
    public List<int> triangles; // Indices of vertices that make up the mesh faces
    public Vector3[] normals; // The normals of the mesh, one per vertex

    // Class initializer
    public MeshData()
    {
        vertices = new List<Vector3>();
        triangles = new List<int>();
    }

    // Returns a Unity Mesh of this MeshData that can be rendered
    public Mesh ToUnityMesh()
    {
        Mesh mesh = new Mesh
        {
            vertices = vertices.ToArray(),
            triangles = triangles.ToArray(),
            normals = normals
        };

        return mesh;
    }

    // Calculates surface normals for each vertex, according to face orientation
    public void CalculateNormals()
    {
        normals = new Vector3[vertices.Count];

        // init list that hold the triangles each vertex is part of
        List<List<int>> surfacesOfVertex = new List<List<int>>();
        for (int vertex_i = 0; vertex_i < vertices.Count; vertex_i++)
        {
            surfacesOfVertex.Add(new List<int>());
        }

        // init list of normals of traingles (n1, n2,..)
        List<Vector3> normalOfSurfaces = new List<Vector3>();

        int tri_index = 0;
        // go over each triangle in jumps of 3 vertices indices
        for (int first_v_i = 0; first_v_i <= triangles.Count-3; first_v_i += 3)
        {
            // for each vertex, add the triangle index it is a part of
            surfacesOfVertex[triangles[first_v_i]].Add(tri_index);
            surfacesOfVertex[triangles[first_v_i + 1]].Add(tri_index);
            surfacesOfVertex[triangles[first_v_i + 2]].Add(tri_index);

            // calc triangle normal
            Vector3 nOfSurface = Vector3.Cross((vertices[triangles[first_v_i]] - vertices[triangles[first_v_i + 2]]), (vertices[triangles[first_v_i + 1]] - vertices[triangles[first_v_i + 2]])).normalized;
            normalOfSurfaces.Add(nOfSurface);
            tri_index++;
        }

        // go over vertices and calc normal of each
        for (int vertex_j = 0; vertex_j < vertices.Count; vertex_j++)
        {
            Vector3 sum = new Vector3();

            // calculate normalized average direction of vertex j
            foreach (int triangle_i in surfacesOfVertex[vertex_j])
            {
                sum += normalOfSurfaces[triangle_i];
            }
            Vector3 n_vector = sum / sum.magnitude;
            normals[vertex_j] = new Vector3(n_vector.x, n_vector.y, n_vector.z);
        }
    }

    // Edits mesh such that each face has a unique set of 3 vertices
    public void MakeFlatShaded()
    {
        // next free index for copied vertices
        int nextIndex = vertices.Count;
        // track if vertex is in more then 1 triangle
        bool[] flags = new bool[vertices.Count];

        for (int i = 0; i < triangles.Count; i++)
        {
            if (flags[triangles[i]] == true)
            {
                // copy vertex to a new one
                vertices.Add(new Vector3(vertices[triangles[i]].x, vertices[triangles[i]].y, vertices[triangles[i]].z));
                // update triangle to hold new vertex
                triangles[i] = nextIndex;
                nextIndex++;
            }
            else
            {
                // mark as seen
                flags[triangles[i]] = true;
            }

        }

    }
}