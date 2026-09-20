@tool
extends EditorPlugin
var PreContextMenuMousePosition: Vector2
enum GlobalContextMenuContent {ToClass, CopyLevelToClipboard, Compile}

var settingsDock: EditorDock


func _ready() -> void:
	_setup_context_menu()
	_setup_dock()

func _setup_dock():
	await EditorInterface.get_editor_main_screen().draw
	settingsDock = EditorDock.new()
	settingsDock.closable = false
	settingsDock.title = "GodotVectorier"
	settingsDock.available_layouts = EditorDock.DOCK_LAYOUT_ALL
	settingsDock.default_slot = EditorDock.DockSlot.DOCK_SLOT_LEFT_BR
	settingsDock.add_child(load("uid://evlnsjo2lx16").instantiate())
	add_dock(settingsDock)

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

		GlobalContextMenuContent.CopyLevelToClipboard:
			EditorAutoload.level.toolbutton_toclipboard.call()

		GlobalContextMenuContent.Compile:
			EditorAutoload.level.toolbutton_compilelevel.call()

class ContextMenuClass2D:
	extends EditorContextMenuPlugin
	enum ContextMenuContent {CreateClass , CreatePlatform}

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
			ContextMenuContent.CreateClass:
				createClass(Helper.get_global_cursor_position())
			


	func createClass(at: Vector2) -> void:
		var popup = PopupMenu.new()
		const prefabsPath: String = "res://user/Prefabs/"

		popup.add_item("- Prefabs -")
		popup.set_item_disabled(0, true)

		for item in DirAccess.get_files_at(prefabsPath):
			popup.add_item(item)

		popup.id_pressed.connect(func(id: int):
			var text: String = popup.get_item_text(id)
			popup.queue_free()

			var scene: PackedScene = ResourceLoader.load(prefabsPath.path_join(text))
			if not scene: return
			var instance = scene.instantiate()
			await Helper.add_node(instance, null if EditorInterface.get_selection().get_selected_nodes().is_empty() else EditorInterface.get_selection().get_selected_nodes()[0])
			if instance is Node2D: instance.global_position = at
			EditorInterface.get_selection().add_node.call_deferred(instance)

			)

		EditorInterface.get_base_control().add_child(popup)
		popup.popup(Rect2(Helper.get_cursor_position(), Vector2.ZERO))
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
