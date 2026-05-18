@tool
extends Node2D
func _ready() -> void:
	set_meta("_edit_lock_" , 1)

func _process(_delta: float) -> void:
	if Helper.is_editing_scene(scene_file_path): 
		return
	global_position = get_global_mouse_position()
	if Input.is_key_pressed(KEY_ESCAPE): queue_free()
