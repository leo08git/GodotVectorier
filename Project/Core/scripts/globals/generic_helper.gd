@tool
extends Node
var eztrigger := EzTrigger.new()

const LocalizationAttributeKeys: PackedStringArray = [
	"eng",
	"rus",
	"ger",
	"ita",
	"fre",
	"spa",
	"tur",
	"por",
	"jap",
	"kor",
	"chi1",
	"chi2",
	"viet",
	"hin",
	"arab",
	"heb",
	"thai",
	"pol",
	"cze",
	"lat",
	"dut",
	"nor",
	"dan",
	"finn",
	"swe",
	"ukr",
	"gre"]
const class_templates = {
	"Image" : preload("uid://dgfvwonfpu1dh") ,
	"Platform" : preload("uid://b7chumel3eljt") ,
	"Trigger" : preload("uid://dmv353gwwqb3w") ,
	"Trapezoid" : preload("uid://dtan3crq3cr7h") ,
	"Spawn" : preload("uid://bjgujtyj283bv") ,
	"Area" : preload("uid://dddq4utkauy12")}
const SettingsPath := "res://settings.json"

## Recursive children get
func get_all_children(root: Node, exclude_scene_instances: bool = true) -> Array[Node]:
	var nodes: Array[Node] = []
	for node in root.get_children():
		if not node.scene_file_path.is_empty() and exclude_scene_instances: 
			node.name = node.scene_file_path.get_file().trim_suffix("."+node.scene_file_path.get_extension())
			continue
		nodes.append(node)
		if node.get_child_count() > 0:
			nodes.append_array(get_all_children(node))
	return nodes

## Seeks files in a path, appends to [b]current_result[/b]. 
func seek_files(path: String, current_result: PackedStringArray, filter: StringName) -> void:
	var dir = DirAccess.open(path)

	if not dir: return 

	dir.list_dir_begin()
	var item_name: String = dir.get_next()

	while not item_name.is_empty():
		if item_name == "." or item_name == "..": 
			item_name = dir.get_next()
			continue

		var current_path: String = path.path_join(item_name)

		if dir.current_is_dir():
			seek_files(current_path, current_result, filter)
		elif filter.is_empty() or item_name.get_extension() == filter:
			current_result.append(ProjectSettings.globalize_path(current_path))

		item_name = dir.get_next()

	dir.list_dir_end()

## returns the filename of every file in said folder and relative path from the folder to the file if there's folders.
## E.g: structure:[code]
## MyFile.png
## MyFolder
## - MyFile.txt [/code][br]
## The output would be [code]["MyFile.png", "MyFolder/MyFile.txt"]
func get_all_files_relative(folder: String , relative_path = "", extension_filter: PackedStringArray = []) -> PackedStringArray:
	var array: PackedStringArray
	
	for file in DirAccess.get_files_at(folder):
		if extension_filter.is_empty() == false and not extension_filter.has(file.get_extension()): continue
		array.append(relative_path.path_join(file))
	for _folder in DirAccess.get_directories_at(folder):
		array.append_array(get_all_files_relative(folder.path_join(_folder) , relative_path.path_join(_folder.get_file())))

	return array

## Adds a node to the tree and set its owner (editor-adapted), if owner_ is null then set it to the editor tree.
func add_node(node: Node, parent: Node = null, owner_: Node = null, undo_allow: bool = false) -> void:
	parent = EditorInterface.get_edited_scene_root() if (parent == null) else parent
	parent.add_child.call_deferred(node)
	await node.tree_entered
	node.owner = EditorInterface.get_edited_scene_root() if (owner_ == null) else owner_

	if undo_allow:
		EditorInterface.get_editor_undo_redo().create_action("Add node to editor")
		EditorInterface.get_editor_undo_redo().add_undo_method(node, "queue_free")
		EditorInterface.get_editor_undo_redo().commit_action()

## are we currently editing said scene?
func is_editing_scene(scene: String) -> bool:
	return EditorInterface.get_edited_scene_root().scene_file_path == scene

## Usage: [code]find_file_extension("res://myfile", [".png", ".txt", ".jpg"])
func find_file_extension(path: String, guesses: PackedStringArray) -> String:
	for ext in guesses:
		var guess = path + ext
		if FileAccess.file_exists(guess):
			return guess
	return path

## Parse a [XMLNode] to an actual [Node] if possible. (returns a [Node2D] with a "is_object" meta if it's a object)
func xml_to_instance(node: XMLNode, debug: bool = false) -> Node:
	var instance: Node = null

	if class_templates.has(node.name):
		instance = class_templates[node.name].instantiate()
		instance.name = node.attributes["Name"] if node.attributes.has("Name") else node.name
	elif node.name == "Object" and !node.standalone:
		instance = Node2D.new()
		instance.name = node.attributes["Name"] if node.attributes.has("Name") else node.name
		instance.set_meta("is_object", 1)
		return instance
	else:
		if debug: printerr("Error while parsing xml class \"%s\" because there's not a template for it." % node.name)
		return null

	match node.name:
		"Image":
			instance.name = node.attributes["ClassName"]
			instance.texture = ResourceLoader.load(find_file_extension(get_setting("textures_folder").path_join(node.attributes["ClassName"]), [".png", ".jpg", ".jpeg"]))
			if not node.children.is_empty():
				var _matrix: XMLNode = node.find_child("Matrix")
				var _dimensions: Vector2 = instance.get("texture").get_size() * instance.get("scale")
		"Trapezoid": 
			instance.set_deferred("type", int(node.attributes["Type"]) - 1)
			(instance as ClassTrapezoid)._type_changed.call_deferred()
			instance.scale.y = instance.scale.x
		"Area":
			instance.area_name = node.attributes["Name"]
		"Trigger":
			instance.name = node.attributes["Name"] if node.attributes.has("Name") else node.name
			if node.has_child("Content"): 
				instance.Command = node.Content.dump_str(true,0,2,false)
		"Spawn":
			(instance as ClassModelSpawn).spawn_animation = node.attributes["Animation"]
			(instance as ClassModelSpawn).spawn_id = node.attributes["Name"]

	return instance

## Creates a [PackedScene] from a node and returns it. if bruteforce_owner_children is true, set the owner of every child to said node before packing (expensive.)
func node_to_scene(node: Node, bruteforce_owner_children: bool = false) -> PackedScene:
	if bruteforce_owner_children:
		for c in get_all_children(node):
			c.owner = node

	var scn = PackedScene.new()
	scn.pack(node)
	return scn

## Short version of ProjectSettings.get_setting
func get_setting(setting: String) -> Variant:
	var result = JSON.parse_string(FileAccess.get_file_as_string(SettingsPath))
	if result == null: push_error("[GenericHelper] Tried getting setting \"%s\" but the settings JSON file content is invalid." % setting)
	else: EditorAutoload.settings = result

	return EditorAutoload.settings.get(setting)

func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 := p0.lerp(p1, t)
	var q1 := p1.lerp(p2, t)

	return q0.lerp(q1, t)

## Find a object's ancestor container (NOT really efficient but yk)
func find_ancestor_container(child: Node) -> Node2D:
	if child == null: return null
	if child.get_parent() is LevelRoot or child.get_parent() is ClassObject:
		return child.get_parent()
	else:
		return find_ancestor_container(child.get_parent())

## Get position relative to nearest container on said class.
## Why? every change I had to make I had to change on every single script :c
func get_class_position(node: ClassBase) -> Vector2:
	var container_ancestor = find_ancestor_container(node)
	var result: Vector2 = container_ancestor.to_local(node.global_position).snappedf(0.01 if get_setting("snap_coordinates_to_2_decimals") else 0.0)
	return result

func get_class_dimensions(node: ClassBase) -> Vector2:
	match node.get_class():
		"Sprite2D":
			return node.global_transform.get_scale() * node.texture.get_size()
		"TextureRect":
			var rect = node.get_global_rect()
			return Vector2(rect.size.x, rect.size.y)

	return Vector2()

func get_viewport_camera_pos() -> Vector2:
	return EditorInterface.get_editor_viewport_2d().global_canvas_transform.origin

func get_viewport_camera_zoom() -> Vector2:
	return EditorInterface.get_editor_viewport_2d().global_canvas_transform.get_scale()

func process_unity_scene(scene: UnityScene, root: Node) -> void:
	for object in scene.OrphanGameObjects:
		process_unity_object(object, root)

func process_unity_object(object: UnityGameObject, parent: Node) -> void:
	var instance = UnityHelper.obj_to_node(object)

	if instance:
		instance.set_meta("qol_excluded", 1)
		var predicted_script_data: Dictionary = evaluate_gameobject_vectorier_script(object)

		add_node(instance, parent if is_instance_valid(parent) else EditorInterface.get_edited_scene_root())

		if is_instance_valid(predicted_script_data.script): 
			instance.set_script(predicted_script_data.script)

			for property in predicted_script_data.tag_properties:
				var value = (predicted_script_data.tag_properties)[property]
				instance.set(property, value)

			for property in predicted_script_data.tag_auto_properties:
				var getter = (predicted_script_data.tag_auto_properties)[property]
				var get_result = object.data.get(getter)
				if get_result == null:
					for c in object.components:
						if not c.data.has(getter): continue
						get_result = c.data.get(getter)
						break

				instance.set(property, get_result)

		object.transform.apply_data(instance)
		for component in object.components: component.apply_data(instance)

		var tname = object.data.get(&"m_Name")
		instance.name = tname if tname != null else "Unnamed"

	for child in object.children:
		process_unity_object(child, instance)

func evaluate_gameobject_vectorier_script(object: UnityGameObject) -> Dictionary:
	var tag = object.data.get("m_TagString", &"")

	var TagOptions: Array[Dictionary] = [

		{
					"script" : preload("uid://b8ywmahn8mr4h") , # Image
					"tag" : ["Backdrop", "Image", "Top Image"] ,
					"tag_properties" : {
						"Backdrop" : {"factor":ClassFactor.PRESETS.Backdrop} ,
						"Top Image" : {"factor":ClassFactor.PRESETS.Overlay}}
		} ,

		{
					"script" : preload("uid://cyjvkka35b16s") , # Platform
					"tag" : "Platform" ,
					"tag_properties" : {} 
		} ,

		{
					"script" : preload("uid://c4ag38qtr1hm7") , # Trigger
					"tag" : "Trigger" ,
					"tag_properties" : {} ,
					"tag_auto_param_pass" : {"Command":"Content"}
		} ,

		{
					"script" : preload("uid://b0w1m0eeyay8k") , # Area
					"tag" : "Area" ,
					"tag_properties" : {} ,
					"tag_auto_param_pass" : {"area_name":"m_Name"}
		} ,

		]

	var tag_properties: Dictionary = {}
	var tag_auto_param_pass: Dictionary = {}
	var target_script: GDScript = null

	for option: Dictionary in TagOptions:
		if ((option.tag is Array) and option.tag.has(tag)) or ((option.tag is String) and option.tag == tag):
			target_script = option.script

			if option.tag is Array:
				tag_properties = option.tag_properties.get(tag, {})
			else:
				tag_properties = option.tag_properties

			tag_auto_param_pass = option.get("tag_auto_param_pass", {})

			break

	if target_script == null:
		push_warning("[Helper while predicting a Unity scene GameObject] Couldn't find a class match for object \"%s\" with tag \"%s\", defaulting to ClassBase." % [object.data.get("m_Name", &""), tag])
		target_script = preload("uid://bqceui7yj7wyd")

	return {
		"script":target_script, 
		"tag_properties": tag_properties ,
		"tag_auto_properties" : tag_auto_param_pass
		}

func is_vector_running() -> bool:
	var output := []
	OS.execute("tasklist", [], output)

	return "Vector.exe" in str(output)

func tree_to_xml(root: Node) -> Array[XMLNode]:
	var result: Array[XMLNode] = []

	for child in root.get_children():
		if (child is ClassBase):
			var xml = child.get_xml_node()
			if not xml: continue

			if child.get_child_count() > 0:
				result.append_array(tree_to_xml(child))

			result.append(xml)

	return result

func ProcessClassXmlMode(class_xml: XMLNode, class_object: ClassBase) -> XMLNode:
	match class_object.TargetMode: # Mode
		ClassBase.TargetModes.ALL: return class_xml
		_:
			var _static = (class_xml.get_child_or_add("Properties")).get_child_or_add("Static")
			var ModeString = ClassBase.TargetModes.keys()[class_object.TargetMode]
			var _selection = XMLNode.new("Selection" , {
				"Choice" : "AITriggers", "Variant" : ModeString }, true)
			_static.append(_selection)
			class_xml.standalone = false

	return class_xml
