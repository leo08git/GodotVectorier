@tool
extends EditorPlugin
var PreContextMenuMousePosition: Vector2
enum GlobalContextMenuContent {ToClass}

class ContextMenuClass2D:
	extends EditorContextMenuPlugin
	enum ContextMenuContent {CreatePlatform}

	func _popup_menu(paths):
		GlobalEditorPlugin.PreContextMenuMousePosition = EditorAutoload.level.get_global_mouse_position()
		for item in ContextMenuContent.keys():
			add_context_menu_item(item.capitalize(), _context_menu_callback.bind(ContextMenuContent[item]))
		for item in GlobalContextMenuContent.keys():
			add_context_menu_item(item.capitalize(), GlobalEditorPlugin._global_context_menu_callback.bind(GlobalContextMenuContent[item]))

	func _context_menu_callback(array: Array, id: ContextMenuContent) -> void:
		match id:
			ContextMenuContent.CreatePlatform:
				var autoplatform = preload("uid://2ksix8oo7cbo").instantiate()
				Helper.add_node(autoplatform)
				autoplatform.global_position = GlobalEditorPlugin.PreContextMenuMousePosition
				EditorInterface.get_selection().add_node(autoplatform)

class ContextMenuClassSceneTree:
	extends EditorContextMenuPlugin
	enum ContextMenuContent {SelectTree}

	func _popup_menu(paths):
		for item in ContextMenuContent.keys():
			add_context_menu_item(item.capitalize(), _context_menu_callback.bind(ContextMenuContent[item]))
		for item in GlobalContextMenuContent.keys():
			add_context_menu_item(item.capitalize(), GlobalEditorPlugin._global_context_menu_callback.bind(GlobalContextMenuContent[item]))

	func _context_menu_callback(array: Array, id: ContextMenuContent) -> void:
		match id:
			ContextMenuContent.SelectTree:
				for selected in EditorInterface.get_selection().get_selected_nodes():
					for selected_children in Helper.get_all_children(selected):
						EditorInterface.get_selection().add_node(selected_children)

func _enter_tree() -> void: _setup_context_menu()

func _setup_context_menu():
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_2D_EDITOR, ContextMenuClass2D.new())
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE, ContextMenuClassSceneTree.new())

func _global_context_menu_callback(data: Array, id: GlobalContextMenuContent) -> void:
	var selection: Array[Node] = EditorInterface.get_selection().get_selected_nodes()

	match id:

		GlobalContextMenuContent.ToClass:
			if selection.is_empty(): printerr("[GlobalEditorPlugin] No selected nodes to apply class script."); return
			for node in selection:
				if node.get_script() != null and !Input.is_key_pressed(KEY_SHIFT): push_warning("[GlobalEditorPlugin] Node %s already has a attached script, ignoring. (hold Shift and try again to force.)" % node.name); continue
				node.set_script(preload("uid://bqceui7yj7wyd"))
