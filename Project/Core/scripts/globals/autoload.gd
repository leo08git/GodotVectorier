@tool
extends Node

var level: LevelRoot = null

# update the current edited level
func _physics_process(_delta: float) -> void:
	var o = EditorInterface.get_edited_scene_root()
	if o is LevelRoot:
		level = o
