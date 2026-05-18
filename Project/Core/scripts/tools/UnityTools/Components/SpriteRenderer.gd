extends UnityComponent
class_name UnityComponentSpriteRenderer


func apply_data(to: Node) -> void:
	if not to.is_inside_tree(): await to.tree_entered
	var sprite_path = get_sprite_path()
	var local_sprite_path: String = Helper.get_setting("textures_folder").path_join(sprite_path.get_file())

	if not FileAccess.file_exists(sprite_path): 
		printerr("[SpriteRenderer] Tried to load image from path \"%s\" but path is not valid. Possibly you deleted a imported texture this SpriteRenderer used, in such case, when importing parse GUIDs again." % sprite_path)
		return

	if to is Sprite2D:
		to.centered = false
		to.z_as_relative = false
		to.texture = load(local_sprite_path)
		to.modulate = get_color()
		to.flip_h = bool(data.m_FlipX)
		to.flip_v = bool(data.m_FlipY)
		to.z_index = data.m_SortingOrder

func get_sprite_path() -> String:
	return scene.guid_handler.get_guid_path(data.m_Sprite.guid)

func get_color() -> Color:
	return UnityHelper.build_color(data.m_Color)
