extends UnityComponent
class_name UnityComponentMonoBehaviour

func get_script_path() -> String:
	return scene.guid_handler.get_guid_path(data.m_Script)
