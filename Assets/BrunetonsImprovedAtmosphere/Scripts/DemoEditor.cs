using UnityEngine;
using UnityEditor;
using System.Collections;

namespace BrunetonsImprovedAtmosphere {

[CustomEditor(typeof(Demo))]
//* [CanEditMultipleObjects]
public class DemoEditor : Editor {

	private bool supported_;

	public void OnEnable() {
      supported_ = SystemInfo.supportsComputeShaders &&
      	SystemInfo.supports3DRenderTextures &&
      	SystemInfo.supports3DTextures;
      	//* && SystemInfo.copyTextureSupport.RTToTexture
      	//* && SystemInfo.copyTextureSupport.Copy3D;
    }

    public override void OnInspectorGUI() {
    	GUI.enabled = true;
    	
    	if (supported_) {
    		Demo demo = (Demo)target;

    		DrawDefaultInspector();

    		if (GUILayout.Button("Precompute")) {
				demo.HardUpdate();
			}

			if (GUI.changed) {
				demo.SoftUpdate();
			}
		}
		else {
			EditorGUILayout.HelpBox("system not supported", MessageType.Error);
		}

		GUIUtility.ExitGUI();
	}
	
}  // class DemoEditor

}  // namespace BrunetonsImprovedAtmosphere
