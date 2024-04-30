using UnityEngine;

namespace UnityTemplateProjects
{
    public class SimpleCameraController : MonoBehaviour
    {
        void Update()
        {
            Vector3 direction = new Vector3();
            if (Input.GetKey(KeyCode.W))
            {
                direction.z += Time.deltaTime;
            }
            if (Input.GetKey(KeyCode.S))
            {
                direction.z -= Time.deltaTime;
            }
            if (Input.GetKey(KeyCode.A))
            {
                direction.x -= Time.deltaTime;
            }
            if (Input.GetKey(KeyCode.D))
            {
                direction.x += Time.deltaTime;
            }
            if (Input.GetKey(KeyCode.Q))
            {
                direction.y -= Time.deltaTime;
            }
            if (Input.GetKey(KeyCode.E))
            {
                direction.y += Time.deltaTime;
            }
            transform.position += direction.normalized * Time.deltaTime;
            
            if (Input.GetKey(KeyCode.Escape))
            {
                Application.Quit();
				#if UNITY_EDITOR
				UnityEditor.EditorApplication.isPlaying = false; 
				#endif
            }
        }
    }
}