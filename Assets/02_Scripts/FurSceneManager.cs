using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using TMPro;

public class FurSceneManager : MonoBehaviour
{
    [SerializeField] private TMP_Text m_PreviousSceneText;
    [SerializeField] private TMP_Text m_CurrentSceneText;
    [SerializeField] private TMP_Text m_NextSceneText;

    [SerializeField] private SceneData m_SceneData;

    public void IncreaseScene()
    {
        m_SceneData.SceneIndex = GetNextSceneIndex();

        UpdateTexts();
        LoadSceneAtIndex(m_SceneData.SceneIndex);
    }

    public void DecreaseScene()
    {
        m_SceneData.SceneIndex = GetPreviousSceneIndex();

        UpdateTexts();
        LoadSceneAtIndex(m_SceneData.SceneIndex);
    }

    private void LoadSceneAtIndex(int index)
    {
        SceneManager.LoadScene(index);
    }

    private int GetNextSceneIndex()
    {
        if (m_SceneData.SceneIndex >= SceneManager.sceneCountInBuildSettings-1)
            return 0;
        else
        {
            return m_SceneData.SceneIndex + 1;
        }
    }

    private int GetPreviousSceneIndex()
    {
        if (m_SceneData.SceneIndex <= 0)
            return SceneManager.sceneCountInBuildSettings-1;
        else
        {
            return m_SceneData.SceneIndex - 1;
        }
    }

    private void UpdateTexts()
    {
        m_PreviousSceneText.text = GetSceneName(GetPreviousSceneIndex());
        m_CurrentSceneText.text = GetSceneName(m_SceneData.SceneIndex);
        m_NextSceneText.text = GetSceneName(GetNextSceneIndex());
    }

    private string GetSceneName(int sceneIndex)
    {
        string sceneName = SceneUtility.GetScenePathByBuildIndex(sceneIndex).ToString();
        sceneName = sceneName.Remove(0, sceneName.LastIndexOf('/')+1);
        sceneName = sceneName.Remove(sceneName.LastIndexOf('.'));
        return sceneName;
    }

    private void Awake()
    {
        m_SceneData.SceneIndex = SceneManager.GetActiveScene().buildIndex;
        UpdateTexts();
    }
}
