@tool
extends Node

var level: LevelRoot = null
var settings: Dictionary = {}

func _init() -> void:
	if !Engine.is_editor_hint(): 
		OS.alert("You are not meant to run a scene. \nTo export a level, click the scene's root and click 'export level to vector'\nIf you don't have that button, then your root does not have the needed script.\nIn that case, search for 'main.gd' in the FileSystem and drag the script to the scene root.")
		OS.kill(OS.get_process_id())

# update the current edited level
func _physics_process(_delta: float) -> void:
	var o = EditorInterface.get_edited_scene_root()
	if o is LevelRoot:
		level = o
