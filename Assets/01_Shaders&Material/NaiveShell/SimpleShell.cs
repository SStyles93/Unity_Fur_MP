using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class SimpleShell : MonoBehaviour {
    public Mesh shellMesh;
    public Shader shellShader;

    public bool updateStatics = true;

    // These variables and what they do are explained on the shader code side of things
    // You can see below (line 70) which shader uniforms match up with these variables
    [Range(1, 256)] public int shellCount = 16;
    [Range(0.0f, 1.0f)] public float shellLength = 0.15f;
    [Range(0.01f, 3.0f)] public float distanceAttenuation = 1.0f;
    [Range(1.0f, 1000.0f)] public float density = 100.0f;
    [Range(0.0f, 1.0f)] public float noiseMin = 0.0f;
    [Range(0.0f, 1.0f)] public float noiseMax = 1.0f;
    [Range(0.0f, 10.0f)] public float thickness = 1.0f;
    [Range(1.0f, 10.0f)] public float curvature = 1.0f;
    [Range(0.0f, 1.0f)] public float displacementStrength = 0.1f;
    [Range(0.0f, 5.0f)] public float occlusionAttenuation = 1.0f;
    [Range(0.0f, 1.0f)] public float occlusionBias = 0.0f;
    public Color shellColor;
    
    private Material shellMaterial;
    private GameObject[] shells;

    private Vector3 displacementDirection = new Vector3(0, 0, 0);

    public Vector3 direction = new Vector3(0, 0, 0);

    void OnEnable() {
        shellMaterial = new Material(shellShader);

        shells = new GameObject[shellCount];

        for (int i = 0; i < shellCount; ++i) {
            shells[i] = new GameObject("Shell " + i.ToString());
            shells[i].AddComponent<MeshFilter>();
            shells[i].AddComponent<MeshRenderer>();
            
            shells[i].GetComponent<MeshFilter>().mesh = shellMesh;
            shells[i].GetComponent<MeshRenderer>().material = shellMaterial;
            shells[i].transform.SetParent(this.transform, false);

            // In order to tell the GPU what its uniform variable values should be, we use these "Set" functions which will set the
            // values over on the GPU. 
            shells[i].GetComponent<MeshRenderer>().material.SetInt("_ShellCount", shellCount);
            shells[i].GetComponent<MeshRenderer>().material.SetInt("_ShellIndex", i);
            shells[i].GetComponent<MeshRenderer>().material.SetFloat("_ShellLength", shellLength);
            shells[i].GetComponent<MeshRenderer>().material.SetFloat("_Density", density);
            shells[i].GetComponent<MeshRenderer>().material.SetFloat("_Thickness", thickness);
            shells[i].GetComponent<MeshRenderer>().material.SetFloat("_Attenuation", occlusionAttenuation);
            shells[i].GetComponent<MeshRenderer>().material.SetFloat("_ShellDistanceAttenuation", distanceAttenuation);
            shells[i].GetComponent<MeshRenderer>().material.SetFloat("_Curvature", curvature);
            shells[i].GetComponent<MeshRenderer>().material.SetFloat("_DisplacementStrength", displacementStrength);
            shells[i].GetComponent<MeshRenderer>().material.SetFloat("_OcclusionBias", occlusionBias);
            shells[i].GetComponent<MeshRenderer>().material.SetFloat("_NoiseMin", noiseMin);
            shells[i].GetComponent<MeshRenderer>().material.SetFloat("_NoiseMax", noiseMax);
            shells[i].GetComponent<MeshRenderer>().material.SetVector("_ShellColor", shellColor);
            //shells[i].transform.localScale += new Vector3(0.0005f * i, 0.0005f * i, 0.0005f * i);
        }
    }

    void Update() {
        float velocity = 1.0f;

        Vector3 currentPosition = this.transform.position;
        direction.Normalize();
        currentPosition += direction * velocity * Time.deltaTime;
        this.transform.position = currentPosition;

        displacementDirection -= direction * Time.deltaTime * 10.0f;
        if (direction == Vector3.zero)
            displacementDirection.y -= 10.0f * Time.deltaTime;

        if (displacementDirection.magnitude > 1) displacementDirection.Normalize();

        Shader.SetGlobalVector("_ShellDirection", displacementDirection);

        if (updateStatics) {
            for (int i = 0; i < shellCount; ++i) {
                shells[i].GetComponent<MeshRenderer>().material.SetInt("_ShellCount", shellCount);
                shells[i].GetComponent<MeshRenderer>().material.SetInt("_ShellIndex", i);
                shells[i].GetComponent<MeshRenderer>().material.SetFloat("_ShellLength", shellLength);
                shells[i].GetComponent<MeshRenderer>().material.SetFloat("_Density", density);
                shells[i].GetComponent<MeshRenderer>().material.SetFloat("_Thickness", thickness);
                shells[i].GetComponent<MeshRenderer>().material.SetFloat("_Attenuation", occlusionAttenuation);
                shells[i].GetComponent<MeshRenderer>().material.SetFloat("_ShellDistanceAttenuation", distanceAttenuation);
                shells[i].GetComponent<MeshRenderer>().material.SetFloat("_Curvature", curvature);
                shells[i].GetComponent<MeshRenderer>().material.SetFloat("_DisplacementStrength", displacementStrength);
                shells[i].GetComponent<MeshRenderer>().material.SetFloat("_OcclusionBias", occlusionBias);
                shells[i].GetComponent<MeshRenderer>().material.SetFloat("_NoiseMin", noiseMin);
                shells[i].GetComponent<MeshRenderer>().material.SetFloat("_NoiseMax", noiseMax);
                shells[i].GetComponent<MeshRenderer>().material.SetVector("_ShellColor", shellColor);
            }
        }
    }

    void OnDisable() {
        for (int i = 0; i < shells.Length; ++i) {
            Destroy(shells[i]);
        }

        shells = null;
    }

    public void OnMove(InputValue value)
    {
        Vector2 movement = value.Get<Vector2>();
        direction.x = movement.x;
        direction.z = movement.y;
    }
    public void OnElevate(InputValue value)
    {
        float movement = value.Get<float>();
        direction.y = movement;
    }
}
