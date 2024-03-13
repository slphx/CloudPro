using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(NoiseGen))]
public class NoiseGenEditor: Editor {

    NoiseGen noiseGen;
    
    void OnEnable() {
        noiseGen = (NoiseGen) target;
    }

    public override void OnInspectorGUI() {
        this.serializedObject.Update();

        EditorGUILayout.PropertyField(this.serializedObject.FindProperty("noiseCompute"));
        EditorGUILayout.PropertyField(this.serializedObject.FindProperty("noiseType"));
        EditorGUILayout.PropertyField(this.serializedObject.FindProperty("resolution"));
        EditorGUILayout.PropertyField(this.serializedObject.FindProperty("seed"));

        if (noiseGen.noiseType != NoiseGen.NoiseType.Hash) {
            EditorGUILayout.PropertyField(this.serializedObject.FindProperty("frequency"));
            EditorGUILayout.PropertyField(this.serializedObject.FindProperty("isTiling"));
            EditorGUILayout.PropertyField(this.serializedObject.FindProperty("octaves"));
            EditorGUILayout.PropertyField(this.serializedObject.FindProperty("sliceDepth"));
            EditorGUILayout.PropertyField(this.serializedObject.FindProperty("inverse"));

        }

        EditorGUILayout.PropertyField(this.serializedObject.FindProperty("logTimer"));

        this.serializedObject.ApplyModifiedProperties();
    }
}