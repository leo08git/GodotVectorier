extends UnityTools
class_name UnityScene

var ScenePath: String
## Scene as a string (Result of parsing, does not change!)
var ContentString: String
var guid_handler: UnityGuidHandler

var RawObjects: Dictionary[StringName, Object] = {}
var GameObjects: Dictionary[StringName, UnityGameObject] = {}
var ImageGuids: PackedStringArray = []
var Settings: Dictionary = {}

var PendingComponents: Array[Dictionary] = []
var PendingPrefabs: Array[Dictionary] = []
var TransformOwners: Dictionary[StringName, UnityGameObject] = {}

## Parses objects from a prefab/unity scene and settings if existant. Before calling this method, make sure to create a guid handler
func read(filepath: String, debug: bool = false) -> void:
	if debug: print("[UnityScene] Opening \"" , filepath  , "\"")

	ScenePath = filepath
	ContentString = FileAccess.get_file_as_string(filepath)

	var yaml = YAML.parse(ContentString.replace(" stripped", ""))
	var objects = yaml.get_documents()

	if ContentString.is_empty(): printerr("Couldn't open, error: %d" % FileAccess.get_open_error()); return
	if objects.is_empty(): printerr("Yaml parse error: %s" % yaml.get_error()); return
	if debug: print("\n[UnityScene] Parsing content.")

	var scene_ids = UnityHelper.get_scene_fileids(ContentString)
	var object_dictionary_index: int = 0

# Parsing raw objects.
	for object_dictionary in objects:
		if object_dictionary is not Dictionary: object_dictionary_index += 1 ;continue

		var object_type: String = object_dictionary.keys()[0]
		var object_properties: Dictionary = object_dictionary.values()[0]
		var object_fileid: String = scene_ids[object_dictionary_index]
		var from_prefab: bool = object_properties.get("m_PrefabInstance", {"fileID":0}).fileID != 0
		var object: Object

		if object_type == "PrefabInstance":
			var prefab_path = str(guid_handler.get_guid_path(object_properties.get("m_SourcePrefab", {"guid":0}).guid))
			PendingPrefabs.append({
				"path" : prefab_path ,
				"data" : (object_properties.duplicate(true)).m_Modification ,
				"fileid" : object_fileid
			})

		elif object_type == "GameObject":
			object = UnityGameObject.build_from_dictionary(object_properties.duplicate(true))
			GameObjects[str(object_fileid)] = object
			RawObjects[str(object_fileid)] = object

		elif UnityComponent.COMPONENTS.has(object_type):

			if from_prefab:
				pass

			else:
				var component_gameobject_id: StringName = str(object_properties.get("m_GameObject", {"fileID":0}).fileID)

				PendingComponents.append({
					"type" : object_type ,
					"properties" : (object_properties.duplicate(true)) ,
					"gameobject_id" : component_gameobject_id ,
					"fileid" : object_fileid
				})

		object_dictionary_index += 1

# Resolving components 	
	for pending_component in PendingComponents:
		var component_type: String = pending_component.type
		var component_properties: Dictionary = pending_component.properties
		var component_fileid: String = pending_component.fileid
		var component_gameobject_id: StringName = pending_component.gameobject_id

		var component = UnityComponent.build_from_dictionary(component_type, component_properties)
		component.scene = self
		component.update_data(component_properties)

		var gameobject: UnityGameObject = GameObjects.get(component_gameobject_id)

		if component is UnityComponentTransform:
			TransformOwners[component_fileid] = gameobject
			gameobject.transform = component
		elif component is UnityComponentSpriteRenderer:
			ImageGuids.append(component.data.m_Sprite.guid)
			gameobject.components.append(component)
		else:
			gameobject.components.append(component)

		component.object = gameobject
		RawObjects[str(component_fileid)] = component

# Resolving prefabs
	for prefabdata in PendingPrefabs:
		var prefab = UnityPrefab.new()
		prefab.open(prefabdata.path, guid_handler)
		prefab.apply_modifications(prefabdata.data)

# Resolving hierarchy
	for object_id: String in GameObjects:
		var object: UnityGameObject = GameObjects[object_id]
		if not object.transform:
			printerr("[UnityScene] A unity scene object has been ignored since it has no transform components.")
			continue
		var transform_father_fileid: StringName = str(object.transform.data.m_Father.fileID)
		if transform_father_fileid == &"0": continue

		var parent_object: UnityGameObject = TransformOwners.get(transform_father_fileid)
		parent_object.children.append(object)

# Resolving textures
	var textures_folder: String = Helper.get_setting("textures_folder")

	for image_guid in ImageGuids:
		var image_path: String = guid_handler.get_guid_path(image_guid)
		var local_image_path: String = textures_folder.path_join(image_path.get_file()) #if FileAccess.file_exists(textures_folder.path_join(image_path.get_file())) == false else textures_folder.path_join(image_path.md5_text().substr(0, 7))

		if (not image_path.begins_with("res://") and not FileAccess.file_exists(local_image_path)):
			push_warning("[UnityScene] \"%s\" is not on the project textures folder, importing it. " % [image_path])
			DirAccess.copy_absolute(image_path, local_image_path)
			guid_handler.set_guid_path(image_guid, local_image_path)

	EditorInterface.get_resource_filesystem().scan()
	await EditorInterface.get_resource_filesystem().filesystem_changed
