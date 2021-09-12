using System;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;


public class CCMeshData
{
    public List<Vector3> points; // Original mesh points
    public List<Vector4> faces; // Original mesh quad faces
    public List<Vector4> edges; // Original mesh edges
    public List<Vector3> facePoints; // Face points, as described in the Catmull-Clark algorithm
    public List<Vector3> edgePoints; // Edge points, as described in the Catmull-Clark algorithm
    public List<Vector3> newPoints; // New locations of the original mesh points, according to Catmull-Clark
}


public static class CatmullClark
{
    static Dictionary<int, HashSet<Vector3>> vertex_faces_points;
    static Dictionary<Tuple<int, int>, int> P1_P2_to_edge_index;
    // Returns a QuadMeshData representing the input mesh after one iteration of Catmull-Clark subdivision.
    public static QuadMeshData Subdivide(QuadMeshData quadMeshData)
    {
        // container for vertex:facesPoints
        vertex_faces_points = new Dictionary<int, HashSet<Vector3>>();
        P1_P2_to_edge_index = new Dictionary<Tuple<int, int>, int>();

        // Create and initialize a CCMeshData corresponding to the given QuadMeshData
        CCMeshData meshData = new CCMeshData();
        meshData.points = quadMeshData.vertices;
        meshData.faces = quadMeshData.quads;
        meshData.edges = GetEdges(meshData);
        meshData.facePoints = GetFacePoints(meshData);
        meshData.edgePoints = GetEdgePoints(meshData);
        meshData.newPoints = GetNewPoints(meshData);

        P1P2toEdgeIndex(meshData);
        return CreateNewQuadMeshData(meshData);
    }

    // Combine facePoints, edgePoints and newPoints into a subdivided QuadMeshData
    public static QuadMeshData CreateNewQuadMeshData(CCMeshData mesh)
    {
        // combine all new points to a single list
        List<Vector3> all_new_points = new List<Vector3>(mesh.newPoints);
        int start_of_edge = all_new_points.Count;
        all_new_points.AddRange(mesh.edgePoints);
        int start_of_face = all_new_points.Count;
        all_new_points.AddRange(mesh.facePoints);

        // create new face data
        List<Vector4> all_new_faces = new List<Vector4>();
        for (int i = 0; i < mesh.faces.Count; i++)
        {
            Vector4 face = mesh.faces[i];
            for (int j = 0; j < 4; j++)
            {
                // get edges (P1, P2) ordered by P1<P2
                Tuple<int, int> t_edge1 = (face[j] < face[(j + 1) % 4]) ? new Tuple<int, int>((int)face[j], (int)face[(j + 1) % 4]) : new Tuple<int, int>((int)face[(j + 1) % 4], (int)face[j]);
                Tuple<int, int> t_edge2 = (face[j] < face[(j + 3) % 4]) ? new Tuple<int, int>((int)face[j], (int)face[(j + 3) % 4]) : new Tuple<int, int>((int)face[(j + 3) % 4], (int)face[j]);
                int edge1 = start_of_edge + P1_P2_to_edge_index[t_edge1];
                int edge2 = start_of_edge + P1_P2_to_edge_index[t_edge2];
                int face_point = start_of_face + i;
                Vector4 new_face = new Vector4(face[j], edge1, face_point, edge2);
                all_new_faces.Add(new_face);
            }
        }
        return new QuadMeshData(all_new_points, all_new_faces);
    }

    // map items (P1, P2): Edge index in mesh edges list
    public static void P1P2toEdgeIndex(CCMeshData mesh)
    {
        for (int i = 0; i < mesh.edges.Count; i++)
        {
            int p1 = (int)mesh.edges[i][0];
            int p2 = (int)mesh.edges[i][1];
            if (p1 > p2) { var temp = p1; p1 = p2; p2 = temp; };
            Tuple<int, int> edge_key = new Tuple<int, int>(p1, p2);
            P1_P2_to_edge_index.Add(edge_key, i);
        }
    }


    // Returns a list of all edges in the mesh defined by given points and faces.
    // Each edge is represented by Vector4(p1, p2, f1, f2)
    // p1, p2 are the edge vertices
    // f1, f2 are faces incident to the edge. If the edge belongs to one face only, f2 is -1
    public static List<Vector4> GetEdges(CCMeshData mesh)
    {
        // container for (p1,p2):{f1,f2} items
        var map = new Dictionary<Tuple<float, float>, HashSet<float>>();
        for (int i = 0; i < mesh.faces.Count; i++)
        {
            Vector4 cur_face = mesh.faces[i];
            for (int j = 0; j < 4; j++)
            {
                //order (p1,p2) where p1<p2
                Tuple<float, float> edge = (cur_face[j] < cur_face[(j + 1) % 4])? new Tuple<float, float> ( cur_face[j], cur_face[(j + 1) % 4] ) : new Tuple<float, float> ( cur_face[(j + 1) % 4], cur_face[j] );
                // add f2 if (p1,p2):{f1} exist 
                if (map.ContainsKey(edge))
                {
                    map[edge].Add(i);
                }
                // add (p1,p2):{f1}
                else
                {
                    map[edge] = new HashSet<float> { i };
                }
            }
        }
        List<Vector4> output = new List<Vector4>();
        foreach (KeyValuePair<Tuple<float,float>, HashSet<float>> item in map)
        {
            float[] faces = new float[item.Value.Count];
            item.Value.CopyTo(faces);
            // add (p1,p2,f1,-1) if f2 do not exist, else add (p1,p2,f1,f2)
            output.Add(new Vector4(item.Key.Item1, item.Key.Item2, faces[0], (faces.Length == 1)? -1 : faces[1]));
        }
        
        return output;
    }

    // Returns a list of "face points" for the given CCMeshData, as described in the Catmull-Clark algorithm 
    public static List<Vector3> GetFacePoints(CCMeshData mesh)
    {
        List<Vector3> output = new List<Vector3>();
        foreach (Vector4 face in mesh.faces)
        {
            List<Vector3> face_vertices = new List<Vector3>();
            for (int i = 0; i < 4; i++)
            {
                face_vertices.Add(mesh.points[(int)face[i]]);
            }
            Vector3 average_vector = face_vertices.Aggregate(new Vector3(0, 0, 0), (s, v) => s + v) / (float)face_vertices.Count;
            output.Add(average_vector);
        }
        return output;
    }

    // Returns a list of "edge points" for the given CCMeshData, as described in the Catmull-Clark algorithm 
    public static List<Vector3> GetEdgePoints(CCMeshData mesh)
    {
        List<Vector3> output = new List<Vector3>();
        foreach (Vector4 edge in mesh.edges)
        {
            List<Vector3> edge_values = new List<Vector3>();
            edge_values.Add(mesh.points[(int)edge[0]]);
            edge_values.Add(mesh.points[(int)edge[1]]);
            edge_values.Add(mesh.facePoints[(int)edge[2]]);
            edge_values.Add(mesh.facePoints[(int)edge[3]]);

            Vector3 average_vector = edge_values.Aggregate(new Vector3(0, 0, 0), (s, v) => s + v) / (float)edge_values.Count;
            output.Add(average_vector);
        }
        return output;
    }

    // Update the global Dictionary vertex_face_points, of shape vertexIndex:{face points}
    private static void updateVertexFacePoints(CCMeshData mesh)
    {
        for (int j = 0; j < mesh.faces.Count; j++)
        {
            Vector4 face = mesh.faces[j];
            for (int i = 0; i < 4; i++)
            {
                if (vertex_faces_points.ContainsKey((int)face[i]))
                {
                    vertex_faces_points[(int)face[i]].Add(mesh.facePoints[j]);
                }
                else
                {
                    vertex_faces_points[(int)face[i]] = new HashSet<Vector3> { mesh.facePoints[j] };
                }
            }
        }
    }

    // Returns a list of new locations of the original points for the given CCMeshData, as described in the CC algorithm 
    public static List<Vector3> GetNewPoints(CCMeshData mesh)
    {
        updateVertexFacePoints(mesh);

        // container of f (averages of vertex' facePoints)
        Vector3[] f_list = new Vector3[mesh.points.Count];
        getAverages(f_list, vertex_faces_points);

        var vertex_edges_midpoints = new Dictionary<int, HashSet<Vector3>>();
        updateVertexEdgesMidpoints(vertex_edges_midpoints, mesh);

        // container of r (averages of vertex' edge midpoints)
        Vector3[] r_list = new Vector3[mesh.points.Count];
        getAverages(r_list, vertex_edges_midpoints);

        List<Vector3> output = new List<Vector3>();
        for (int i = 0; i < mesh.points.Count; i++)
        {
            int n = vertex_faces_points[i].Count;
            output.Add((f_list[i] + (2 * r_list[i]) + ((n - 3) * mesh.points[i])) / n);
        }

        return output;
    }

    // calculate coordinate avarages for each map item vectors, and updates lst with result
    private static void getAverages(Vector3[] lst, Dictionary<int, HashSet<Vector3>> map)
    {
        foreach (KeyValuePair<int, HashSet<Vector3>> item in map)
        {
            lst[item.Key] = (item.Value.Aggregate(new Vector3(0, 0, 0), (s, v) => s + v) / (float)item.Value.Count);
        }
    }

    // Update the Dictionary vertex_edges_midpoints, of shape vertexIndex:{edges midpoints}
    private static void updateVertexEdgesMidpoints(Dictionary<int, HashSet<Vector3>> vertex_edges_midpoints, CCMeshData mesh)
    {
        for (int j = 0; j < mesh.edges.Count; j++)
        {
            Vector4 edge = mesh.edges[j];
            int p1 = (int)edge[0];
            int p2 = (int)edge[1];
            Vector3 mid = (mesh.points[p1] + mesh.points[p2]) / (float)2;

            // update p1
            if (vertex_edges_midpoints.ContainsKey(p1))
            {
                vertex_edges_midpoints[p1].Add(mid);
            }
            else
            {
                vertex_edges_midpoints[p1] = new HashSet<Vector3> { mid };
            }

            // update p2
            if (vertex_edges_midpoints.ContainsKey(p2))
            {
                vertex_edges_midpoints[p2].Add(mid);
            }
            else
            {
                vertex_edges_midpoints[p2] = new HashSet<Vector3> { mid };
            }
        }
    }
}
