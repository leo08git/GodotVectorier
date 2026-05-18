@tool
extends EditorPlugin
var vectorier_button: MenuButton
var vectorier_button_popup: PopupMenu

const SETTINGS_CONFIG_HEADER = "GodotVectorier/config"

var SETTINGS: Array[Dictionary] = [
{
			"start_value" : "" ,
			"name" : SETTINGS_CONFIG_HEADER.path_join("game_folder") ,
			"type" : TYPE_STRING ,
			"hint" : PROPERTY_HINT_GLOBAL_DIR ,
			"hint_string" : "" ,
	} ,

	{
			"start_value" : "" ,
			"name" : SETTINGS_CONFIG_HEADER.path_join("textures_folder") ,
			"type" : TYPE_STRING ,
			"hint" : PROPERTY_HINT_GLOBAL_DIR ,
			"hint_string" : "" ,
	} ,

	{
			"start_value" : "" ,
			"name" : SETTINGS_CONFIG_HEADER.path_join("objects_folder") ,
			"type" : TYPE_STRING ,
			"hint" : PROPERTY_HINT_GLOBAL_DIR ,
			"hint_string" : "" ,
	} ,

	{
			"start_value" : false ,
			"name" : SETTINGS_CONFIG_HEADER.path_join("report_level_issues") ,
			"type" : TYPE_BOOL ,
			"hint" : PROPERTY_HINT_NONE ,
	} ,

	{
			"start_value" : false ,
			"name" : SETTINGS_CONFIG_HEADER.path_join("open_vector_after_compile") ,
			"type" : TYPE_BOOL ,
			"hint" : PROPERTY_HINT_NONE ,
	} ,

	{
			"start_value" : false ,
			"name" : SETTINGS_CONFIG_HEADER.path_join("snap_coordinates_to_2_decimals") ,
			"type" : TYPE_BOOL ,
			"hint" : PROPERTY_HINT_NONE ,
	} ,

	{
			"start_value" : "" ,
			"name" : SETTINGS_CONFIG_HEADER.path_join("log_map_path") ,
			"type" : TYPE_STRING ,
			"hint" : PROPERTY_HINT_FILE_PATH ,
			"hint_string" : "" ,
	} ,

]

func _init() -> void:
	print("Initialized GodotVectorier menu handler")
	_refresh_button.call_deferred()

func _refresh_settings() -> void:
	for setting: Dictionary in SETTINGS:
		if not ProjectSettings.has_setting(setting.name):
			ProjectSettings.set_setting(setting.name, setting.start_value)
			ProjectSettings.add_property_info({
				"name" : setting.name ,
				"type" : setting.type ,
				"hint" : setting.hint ,
				"hint_string" : "" if not setting.has("hint_string") else setting.hint_string ,
			})
		ProjectSettings.set_initial_value(setting.name, setting.start_value)

func _refresh_button() -> void:
	_refresh_settings()
# Delete old button if any exists
	if vectorier_button: vectorier_button.queue_free() 

	var vectorier_items: Array = preload("uid://ni5lxu55502d").templates
	var button := MenuButton.new()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, button)
	button.text = "GodotVectorier"
	vectorier_button_popup = button.get_popup()
	vectorier_button = button

	for item: VectorierButtonTemplatesHolder in vectorier_items:
		_helper_parse_item(item)


	vectorier_button_popup.id_pressed.connect(func(id: int):
		_vectorier_button_callback(vectorier_button_popup.get_item_metadata(id), id)
		)

	push_warning("[Editor manager] Refreshed editor buttons")

func _vectorier_button_callback(script: GDScript, id: int) -> void:
	var placeholder = script.new()
	placeholder.call("trigger", id)

func _helper_parse_item(item: VectorierButtonTemplatesHolder, to_submenu: PopupMenu = null):
	if item.is_submenu:
		var sub := PopupMenu.new()
		sub.id_pressed.connect(func(id: int):
			_vectorier_button_callback(sub.get_item_metadata(id), id)
			)
		vectorier_button_popup.add_submenu_node_item(item.template_name, sub)
		for subitem in item.children:
			_helper_parse_item(subitem, sub)

	else:
		var menu := to_submenu if is_instance_valid(to_submenu) else vectorier_button_popup
		menu.add_item(item.template_name)
		var gd: GDScript = item.template_script
		menu.set_item_tooltip(menu.item_count - 1, item.template_tooltip)
		menu.set_item_metadata(menu.item_count - 1, gd)
