using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(NoiseGenerator))]
public class NoiseGenEditor: Editor {

    NoiseGenerator noiseGenerator;
    
    void OnEnable() {
        noiseGenerator = (NoiseGenerator) target;
    }

    public override void OnInspectorGUI() {
        this.serializedObject.Update();

        EditorGUILayout.PropertyField(this.serializedObject.FindProperty("noiseCompute"));
        EditorGUILayout.PropertyField(this.serializedObject.FindProperty("noiseType"));
        EditorGUILayout.PropertyField(this.serializedObject.FindProperty("resolution"));
        EditorGUILayout.PropertyField(this.serializedObject.FindProperty("seed"));

        if (noiseGenerator.noiseType != NoiseGenerator.NoiseType.Hash) {
            EditorGUILayout.PropertyField(this.serializedObject.FindProperty("frequency"));
            EditorGUILayout.PropertyField(this.serializedObject.FindProperty("isTiling"));
            EditorGUILayout.PropertyField(this.serializedObject.FindProperty("octaves"));
            EditorGUILayout.PropertyField(this.serializedObject.FindProperty("sliceDepth"));
            EditorGUILayout.PropertyField(this.serializedObject.FindProperty("inverse"));
        }

        if (GUILayout.Button ("Save")) {
            noiseGenerator.Save();
        }

        EditorGUILayout.PropertyField(this.serializedObject.FindProperty("logTimer"));

        this.serializedObject.ApplyModifiedProperties();
    }
}