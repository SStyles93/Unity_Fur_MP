using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class HLSLGeom_Controler : MonoBehaviour
{
    private Vector3 displacementDirection = new Vector3(0, 0, 0);

    public Vector3 direction = new Vector3(0, 0, 0);

    // Start is called before the first frame update
    void Start()
    {
    }

    // Update is called once per frame
    void Update()
    {
        float velocity = 1.0f;

        Vector3 currentPosition = this.transform.position;
        direction.Normalize();
        currentPosition += direction * velocity * Time.deltaTime;
        this.transform.position = currentPosition;

        displacementDirection += direction * Time.deltaTime * 10.0f;
        if (direction == Vector3.zero)
            displacementDirection.y += 10.0f * Time.deltaTime;

        if (displacementDirection.magnitude > 1) displacementDirection.Normalize();

        Shader.SetGlobalVector("_ShellDirection", displacementDirection);
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
