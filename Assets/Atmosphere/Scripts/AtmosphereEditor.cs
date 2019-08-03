// Dan Shervheim
// danielshervheim.com
// August 2019

using UnityEditor;
using UnityEngine;

namespace BrunetonsImprovedAtmosphere
{
    [CustomEditor(typeof(Atmosphere))]
    public class AtmosphereEditor : Editor
    {
        private Atmosphere atmosphere;

        public void OnEnable()
        {
            atmosphere = (Atmosphere)target;
        }

        public override void OnInspectorGUI()
        {
            DrawDefaultInspector();

            if (SystemInfo.supportsComputeShaders)
            {
                if (GUILayout.Button("Compute"))
                {
                    atmosphere.MakeAtmosphere();
                }
            }
            else
            {
                EditorGUILayout.HelpBox("Requires a GPU that supports compute shaders.", MessageType.Error);
            }
        }
    }  // AtmosphereEditor
}  // BrunetonsImprovedAtmosphere
