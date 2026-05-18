extends UnityTools
class_name UnityPrefab

var scene: UnityScene
var owner: UnityScene

func apply_modifications(modifications: Dictionary) -> void:
	for modification in modifications.m_Modifications:
		var target_fileid = modification.target.fileID
		var target: Object = scene.RawObjects[str(target_fileid)]
		var property: String = modification.propertyPath
		var value: Variant = modification.value

		#print(target_fileid)
		#print(target)
		#print(property)
		#print(value)

func open(path: String, guidhandler: UnityGuidHandler) -> void:
	scene = UnityScene.new()
	scene.guid_handler = guidhandler
	scene.read(path)
