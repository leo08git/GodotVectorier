@tool
extends Utilities
## (UNSTABLE AND VERY SLOW!) loads a Unity .prefab/.unity file, gets the resources by getting each avaliable UID on [member resource_path] before parsing a prefab and using it to load resources.
class_name UnitySceneLoader

@export_tool_button("Import prefab") var tb_y = import

@export var root: Node
@export_global_file("*.prefab", "*.unity") var scene_path: String = ""
## Path to get all guids that are needed. [br]
## Guids are the IDs unity use to load resources, without them you wouldn't be able to import textures or prefabs. [br]
## My recommendation is scanning your Assets/ folder to make sure everything will work as expected.
@export_global_dir var guids_path: String = ""
## Force parsing even if we already parsed guids_path.
@export var force_guid_parse: bool = false

var guid_handler := UnityGuidHandler.new()

func import(): 
	if not root: printerr("No root node specified.") ;return
	if scene_path.is_empty() or not FileAccess.file_exists(scene_path): printerr("No prefab path specified.") ;return
	if guids_path.is_empty() or not DirAccess.dir_exists_absolute(guids_path): printerr("No resource folder specified.") ;return
	print("[UnitySceneLoader] Started importing")
	if not guid_handler: guid_handler = UnityGuidHandler.new()

	print("[UnitySceneLoader] Parsing Guid's...")
	guid_handler.parse_path(guids_path, force_guid_parse)
	await guid_handler.parse_finished

	var scene := UnityScene.new()
	scene.guid_handler = guid_handler
	await scene.read(scene_path)

	Helper.process_unity_scene(scene, root)
