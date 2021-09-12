using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterAnimator : MonoBehaviour
{
    public TextAsset BVHFile;       // The BVH file that defines the animation and skeleton
    public bool animate;            // Indicates whether or not the animation should be running

    private BVHData data;           // BVH data of the BVHFile will be loaded here
    private int currFrame = 0;      // Current frame of the animation
    private DateTime lastIncrement; // Last time currFrame was incremented 
    
    // Start is called before the first frame update
    void Start()
    {
        BVHParser parser = new BVHParser();
        data = parser.Parse(BVHFile);

        CreateJoint(data.rootJoint, Vector3.zero);
        lastIncrement = DateTime.Now;
    }

    // Returns a Matrix4x4 representing a rotation aligning the up direction of an object with the given v
    Matrix4x4 RotateTowardsVector(Vector3 v)
    {
        v = v.normalized;
        Matrix4x4 rx = MatrixUtils.RotateX(Mathf.Rad2Deg * (-Mathf.Atan2(v.z, v.y)));
        Matrix4x4 rz = MatrixUtils.RotateZ(Mathf.Rad2Deg * Mathf.Atan2(v.x, Mathf.Sqrt(Mathf.Pow(v.y, 2) + Mathf.Pow(v.z, 2))));
        return rx.transpose * rz.transpose;
    }

    // Creates a Cylinder GameObject between two given points in 3D space
    GameObject CreateCylinderBetweenPoints(Vector3 p1, Vector3 p2, float diameter)
    {
        GameObject bone = GameObject.CreatePrimitive(PrimitiveType.Cylinder);

        // Calc transform metrics, constructed from translate, rotate & scale
        Matrix4x4 t = MatrixUtils.Translate((p1 + p2)/2);
        Matrix4x4 r = RotateTowardsVector(p2 - p1);
        Vector3 diameterVector = new Vector3(diameter, (p2 - p1).magnitude/2, diameter);
        Matrix4x4 s = MatrixUtils.Scale(diameterVector);

        MatrixUtils.ApplyTransform(bone, t * r * s);
        return bone;
    }

    // Creates a GameObject representing a given BVHJoint and recursively creates GameObjects for it's child joints
    GameObject CreateJoint(BVHJoint joint, Vector3 parentPosition)
    {
        joint.gameObject = new GameObject(joint.name);
        GameObject jointSphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        jointSphere.transform.parent = joint.gameObject.transform;

        Matrix4x4 s = (joint.name == "Head") ? MatrixUtils.Scale(new Vector3(8, 8, 8)) : MatrixUtils.Scale(new Vector3(2, 2, 2));
        MatrixUtils.ApplyTransform(jointSphere, s);

        Vector3 vec = parentPosition + joint.offset;
        Matrix4x4 t = MatrixUtils.Translate(vec);
        MatrixUtils.ApplyTransform(joint.gameObject, t);

        foreach (BVHJoint child in joint.children)
        {
            // Creat joint's children recursivly
            CreateJoint(child, jointSphere.transform.position);
            
            // Create bones
            GameObject bone = CreateCylinderBetweenPoints(jointSphere.transform.position, jointSphere.transform.position + child.offset, 0.5f);
            bone.transform.parent = joint.gameObject.transform;
        }
        
        return joint.gameObject;
    }

    // Transforms BVHJoint according to the keyframe channel data, and recursively transforms its children
    private void TransformJoint(BVHJoint joint, Matrix4x4 parentTransform, float[] keyframe)
    {
        Matrix4x4 rx = MatrixUtils.RotateX(keyframe[joint.rotationChannels.x]);
        Matrix4x4 ry = MatrixUtils.RotateY(keyframe[joint.rotationChannels.y]);
        Matrix4x4 rz = MatrixUtils.RotateZ(keyframe[joint.rotationChannels.z]);

        // Calc rotation matrix based on joint's rotation order
        Matrix4x4 r;
        if (joint.rotationOrder == new Vector3(0, 1, 2))
        {
            r = rx * ry * rz;
        }
        else if (joint.rotationOrder == new Vector3(0, 2, 1))
        {
            r = rx * rz * ry;
        }
        else if (joint.rotationOrder == new Vector3(1, 0, 2))
        {
            r = ry * rx * rz;
        }
        else if (joint.rotationOrder == new Vector3(1, 2, 0))
        {
            r = rz * rx * ry;
        }
        else if (joint.rotationOrder == new Vector3(2, 0, 1))
        {
            r = ry * rz * rx;
        }
        else 
        // (joint.rotationOrder == new Vector3(2, 1, 0))
        {
            r = rz * ry * rx;
        }

        Matrix4x4 t = MatrixUtils.Translate(joint.offset);
        Matrix4x4 s = Matrix4x4.identity;
        Matrix4x4 m = t * r * s;
        MatrixUtils.ApplyTransform(joint.gameObject, parentTransform * m);

        foreach (BVHJoint child in joint.children)
        {
            // Recursivly transform joint's children
            TransformJoint(child, parentTransform * m, keyframe);
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (animate)
        {
            // Transform joint based on channel data
            Vector3 v = new Vector3(
                data.keyframes[currFrame][data.rootJoint.positionChannels.x],
                data.keyframes[currFrame][data.rootJoint.positionChannels.y],
                data.keyframes[currFrame][data.rootJoint.positionChannels.z]
                );
            TransformJoint(data.rootJoint, MatrixUtils.Translate(v), data.keyframes[currFrame]);
            
            // increment the currFrame class property at the correct frame rate
            double incrementDiff = (DateTime.Now - lastIncrement).TotalSeconds;
            if (incrementDiff > data.frameLength)
            {
                currFrame += (int)(incrementDiff/data.frameLength);
                lastIncrement = DateTime.Now;
            }

            // if end of animation, reset frame to create a loop
            if (currFrame >= data.numFrames) { currFrame = 0; }
        }
    }
}
