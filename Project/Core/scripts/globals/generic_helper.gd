@tool
extends Node

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
	"Area" : preload("uid://dddq4utkauy12")
}

## Looks inside a dz, when created it automatically decompiles the dz.
class DzSeeker:
	var dz_path: String = ""
	var decompiled_directory: String = ""
	var state: Error = OK

## Decompiles the dz right away. Usage: DzSeeker.new("level_xml")
	func _init(dz_name: String, backup: bool = true) -> void:
		dz_name += ".dz"
		if Helper.get_setting("game_folder").is_empty(): 
			printerr("[DzSeeker] The game path folder is not set. Cancelling operation")
			state = ERR_BUG
			return
		elif not DirAccess.dir_exists_absolute(Helper.get_setting("game_folder")): 
			printerr("[DzSeeker] The game path folder is invalid! Cancelling operation")
			state = ERR_BUG
			return

		dz_path = Helper.get_setting("game_folder").path_join(dz_name)
		decompiled_directory = dz_path.get_basename()
		var pre_decompiled: bool = DirAccess.dir_exists_absolute(decompiled_directory)

		if pre_decompiled:
			pass
		else:
			if backup:
				var copy_path: String = dz_path.get_basename() + "_backup.dz"
				DirAccess.copy_absolute(dz_path, copy_path)
			EditorDzHandler.dzip_decompile(dz_path)
			await EditorDzHandler.decompile_process_terminated

	## Returns the absolute path for a file present in the dz.
	func get_file(filename: String) -> String:
		return decompiled_directory.path_join(filename)

	func compile() -> bool:
		if EditorDzHandler.dzip_compile(decompiled_directory) != OK: return false
		await EditorDzHandler.compile_process_terminated
		return true
class VectorLevel:
	var factors: Array[float] = []
	var objects: Array[ClassBase] = []
	var models: Array[ClassModel] = []

	var max_coins: int = 40
	var music_name: String = "music_dinamic"
	var music_volume: float = 0.2
	var sets: Dictionary[String, String] = {}

	func _init(root: LevelRoot) -> void:
		if is_instance_valid(root):
			max_coins = root.max_coins
			music_name = root.music_name
			music_volume = root.music_volume
			sets = root.sets
			_parse_objects(Helper.get_all_children(EditorAutoload.level))

	func _parse_objects(list: Array) -> void:
		for object in list:
			if object is not ClassBase: 
				if Helper.get_setting("report_level_issues"):
					push_warning('Ignoring %s because it is not a recognized object.' % object.name)
				continue

			objects.append(object)
			if object is ClassImage or object is ClassFactor:
				if factors.has(object.factor): continue
				factors.append(object.factor)


	func get_string() -> String:
		factors.sort()
		var node_root := XMLNode.new("Root")
		var node_sets := XMLNode.new("Sets")
		var node_music := XMLNode.new("Music" , {"Name":music_name, "Volume": music_volume} , true)
		var node_models_common_mode := XMLNode.new("Models" , {"Choice":"AITriggers", "Variant":"CommonMode"})
		var node_models_hunter_mode := XMLNode.new("Models" , {"Choice":"AITriggers", "Variant":"HunterMode"})
		var node_max_coins_value := XMLNode.new("Coins" , {"Value":max_coins} , true)
		var node_track := XMLNode.new("Track")
		var factor_nodes: Dictionary[float, XMLNode] = {}

		for _set_ in sets:
			var set_node := XMLNode.new(_set_, {"FileName":sets[_set_]})
			set_node.standalone = true
			node_sets.children.append(set_node)

		for factor in factors:
			@warning_ignore("incompatible_ternary")
			var factor_node := XMLNode.new("Object" , {"Factor":factor if fmod(factor, 1) != 0 else int(factor)})
			var factor_content := XMLNode.new("Content")
			factor_nodes[factor] = factor_content

			factor_node.children.append(factor_content)
			node_track.children.append(factor_node)

		var last_childholder: ClassChildContainer = null
		var last_childholder_xmlnode: XMLNode = null

		for object in objects:
			if not object.enabled: continue
			var object_xmlnode = Helper.instance_to_xml(object)
			if not is_instance_valid(object_xmlnode): continue

			if object_xmlnode.attributes.has("Color") and object_xmlnode.attributes.Color is Color:
				object_xmlnode.attributes.Color = "#%s" % (object_xmlnode.attributes.Color as Color).to_html(0)

			if object is ClassChildContainer:
				last_childholder = object
				var content = XMLNode.new("Content")
				object_xmlnode.children.append(content)
				last_childholder_xmlnode = content

			if object is ClassModel:
				match object.mode:
					object.modes.COMMON_MODE:
						node_models_common_mode.children.append(object_xmlnode)
					object.modes.HUNTER_MODE:
						node_models_hunter_mode.children.append(object_xmlnode)

			elif is_instance_valid(last_childholder) and is_instance_valid(object) and last_childholder.is_ancestor_of(object):
				last_childholder_xmlnode.children.append(object_xmlnode)

			elif object is ClassImage or object is ClassFactor: 
				factor_nodes.get_or_add(object.factor , XMLNode.new()).children.append(object_xmlnode)

		node_root.children.append_array([
			node_sets ,
			node_music ,
			node_models_common_mode ,
			node_models_hunter_mode ,
			node_max_coins_value ,
			node_track])

		return node_root.dump_str(true)
class LevelHandler:
	static func compile_map(root: LevelRoot, copy_content: bool, save_to_game: bool) -> void:
## Validating
		if root.get_children().is_empty(): printerr("No objects present. Cancelling operation"); return
		print_rich("[color=orange]Compile map process started...")

## Get all objects, create a vector level class and parse them objects
		var vectorlevel = Helper.VectorLevel.new(root)
		print_rich("[color=green]Parsed level")

## info
		var xml: String = vectorlevel.get_string()
		var include_thumbnail: bool = false if EditorAutoload.level.level_thumbnail_path.is_empty() else true
		var include_title: bool = false if EditorAutoload.level.level_name.is_empty() else true
		if copy_content: DisplayServer.clipboard_set(xml)
		if not save_to_game: 
			print_rich("[color=orange]Operation finished yaaaay")
			return

		var dzseeker: DzSeeker = await DzSeeker.new("level_xml")
		if dzseeker.state != OK: 
			printerr("Error while seeking level_xml.dz.")
			return
		var map_file_name = root.override_this_level + ".xml"
		var map_file_path = dzseeker.get_file(map_file_name)
		print_rich("[i][color=lightblue]Informations:\n	level dz path: %s\n	map file path: %s" % [
			dzseeker.dz_path ,
			map_file_path])

## save xml to file
		print_rich("[color=lightyellow]Opening file path %s." % map_file_path)
		var f = FileAccess.open(map_file_path , FileAccess.WRITE)
		if FileAccess.get_open_error() != OK: printerr("Unable to open path %s, error %d." % [map_file_path, FileAccess.get_open_error()]); return

		print_rich("[color=lightyellow]Storing XML...")
		var store_result = f.store_string(xml)
		if not store_result: # results false if we couldnt store it for some reason.
			printerr("Unable to store xml on file %s. Error: %s" % [map_file_path, str(f.get_error())])
			f.close()
			return
		f.close()

## compile dz file
		print_rich("[color=green]Opened and stored content in the XML file, now compiling. [color=yellow](May take a while on the first time.)")
		if not await (dzseeker.compile()): printerr("Couldn't compile the dz."); return
		print_rich("[color=green]Compiled")

## Handle thumbnail if needed
		if include_thumbnail and EditorAutoload.level.level_thumbnail_path != EditorAutoload.level._processed_thumbnail_path:
			if not FileAccess.file_exists(EditorAutoload.level.level_thumbnail_path):
				printerr("Level thumbnail path is invalid."); return
			print_rich("\n[color=yellow]Processing thumbnail change... Opening GUI_2048_1536.dz")
			var thumbnail_seeker: DzSeeker = await DzSeeker.new("GUI_2048_1536")
			if thumbnail_seeker.state != OK: printerr("Couldn't create a DZseeker for thumbnail processing."); return
			var thumbnail_filename: String =  "%s.png" % EditorAutoload.level.override_this_level
			var override_path: String = thumbnail_seeker.get_file(thumbnail_filename)
			print_rich("[color=green]Opened, overriding image")
			if DirAccess.copy_absolute(EditorAutoload.level.level_thumbnail_path, override_path) != OK: 
				printerr("Unable to copy from \"%s\" to \"%s\", Cancelling operation." % [EditorAutoload.level.level_thumbnail_path, override_path]); return
			print_rich("[color=yellow]Now compiling...")
			if not await thumbnail_seeker.compile(): printerr("Couldn't compile thumbnail."); return
			print_rich("[color=green]Compiled thumbnail. [GUI_2048_1536]")
			EditorAutoload.level._processed_thumbnail_path = EditorAutoload.level.level_thumbnail_path

## Handle title if needed
		if include_title and EditorAutoload.level.level_name != EditorAutoload.level._processed_level_name:
			print_rich("\n[color=yellow]Processing title... Opening common_xml.dz")
			var title_seeker: DzSeeker = await DzSeeker.new("common_xml")
			if title_seeker.state != OK: printerr("Couldn't create a DZseeker for title processing."); return
			var localization_path: String = title_seeker.get_file("localization_all.xml")
			var xml_key: String = "item_%s" % EditorAutoload.level.override_this_level
			print_rich("[color=green]Opened, initializing XMLNode and altering language keys...")

			var xml_root: XMLNode = XML.parse_file(localization_path).root
			var xml_title_holder: XMLNode = xml_root.find_child(xml_key)
			for lang_key in LocalizationAttributeKeys:
				xml_title_holder.attributes.set(lang_key, EditorAutoload.level.level_name)

			print_rich("[color=yellow]Saving")
			FileAccess.open(localization_path, FileAccess.WRITE).store_string(xml_root.dump_str(1))

			print_rich("[color=green]Saved! [color=yellow]Now compiling...")
			if not await title_seeker.compile(): printerr("Couldn't compile title."); return
			print_rich("[color=green]Compiled title. [common_xml]")
			EditorAutoload.level._processed_level_name = EditorAutoload.level.level_name

		print_rich("\n[color=orange]Successfully compiled the level :D")
		var logpath = Helper.get_setting("log_map_path") as String
		if not logpath.is_empty(): 
			print_rich("[color=yellow]Created log file!")
			FileAccess.open(logpath, FileAccess.WRITE).store_string("This is a log automatically generated after compiling a level to game. (%s)\nContent:\n\n%s" % [Time.get_time_string_from_system() ,xml])

		var b = Helper.get_setting("open_vector_after_compile")
		if (b is bool and b == true):
			OS.shell_open("steam://rungameid/248970")

## Recursive children get
func get_all_children(root: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for node in root.get_children():
		nodes.append(node)
		if node.get_child_count() > 0:
			nodes.append_array(get_all_children(node))
	return nodes

func find_local_file(filename: StringName, default: StringName = "") -> String:
	var paths: PackedStringArray = []
	seek_files(get_setting("textures_folder"), paths, filename.get_extension())
  
	for path in paths:
		if path.get_file() == filename:
			return path
	return default

## Seeks files in a path, appends to [b]current_result[/b]. if local is true, use res:// format.
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
func add_node(node: Node, parent: Node, owner_: Node = null, undo_allow: bool = false) -> void:
	parent.add_child(node)
	node.owner = EditorInterface.get_edited_scene_root() if (owner_ == null) else owner_

	if undo_allow:
		EditorInterface.get_editor_undo_redo().create_action("Create platform on image")
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
			instance.texture = ResourceLoader.load(find_file_extension(Helper.get_setting("textures_folder").path_join(node.attributes["ClassName"]), [".png", ".jpg", ".jpeg"]))
			if not node.children.is_empty():
				var _matrix: XMLNode = node.find_child("Matrix")
				var _dimensions: Vector2 = instance.get("texture").get_size() * instance.get("scale")
		"Trapezoid":
			var idx = (instance.scale as Vector2).max_axis_index()
			instance.scale = Vector2(instance.scale[idx], instance.scale[idx])
			instance.set_deferred("type", int(node.attributes["Type"]) - 1)
			(instance as ClassTrapezoid)._type_changed.call_deferred()
		"Area":
			instance.area_name = node.attributes["Name"]
		"Trigger":
			instance.name = node.attributes["Name"] if node.attributes.has("Name") else node.name
			if node.has_child("Content"): 
				instance.Command = node.Content.dump_str(true,0,2,false)
		"Spawn":
			(instance as ClassSpawnLocation).spawn_animation = node.attributes["Animation"]
			(instance as ClassSpawnLocation).spawn_id = node.attributes["Name"]

	return instance

## Parse an [ClassBase] to [XMLNode] if possible. [i](Will return null if instance is not a [ClassBase])
func instance_to_xml(instance: Node) -> XMLNode:
	if instance is ClassBase: return instance.get_xml_node()
	return null

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
	return ProjectSettings.get_setting(EditorMenuHandler.SETTINGS_CONFIG_HEADER.path_join(setting))

func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 := p0.lerp(p1, t)
	var q1 := p1.lerp(p2, t)

	return q0.lerp(q1, t)

## Find a object's ancestor container (NOT really efficient but yk)
func find_ancestor_container(child: Node) -> Node2D:
	if child == null: return null
	if child.get_parent() is LevelRoot or child.get_parent() is ClassChildContainer:
		return child.get_parent()
	else:
		return find_ancestor_container(child.get_parent())

## Get position relative to nearest container on said class.
## Why? every change I had to make I had to change on every single script :c
func get_class_position(node: ClassBase) -> Vector2:
	var container_ancestor = find_ancestor_container(node)
	var result: Vector2 = container_ancestor.to_local(node.global_position).snappedf(0.01 if get_setting("snap_coordinates_to_2_decimals") else 0.0)
	return result

func get_viewport_camera_pos() -> Vector2:
	return EditorInterface.get_editor_viewport_2d().global_canvas_transform.origin

func get_viewport_camera_zoom() -> Vector2:
	return EditorInterface.get_editor_viewport_2d().global_canvas_transform.get_scale()

func process_unity_scene(scene: UnityScene, root: Node) -> void:
	for object in scene.GameObjects.values():
		if not object.transform:
			printerr("[Helper while processing unity scene] A unity scene object has been ignored since it has no transform components.")
			continue
		if str(object.transform.data.m_Father.fileID) == &"0":
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
					"tag" : ["Area"] ,
					"tag_properties" : {} ,
					"tag_auto_param_pass" : {"area_name":"m_Name"}
		} ,

		]

	var tag_properties: Dictionary = {}
	var tag_auto_param_pass: Dictionary = {}
	var target_script: GDScript = null

	for option: Dictionary in TagOptions:
		if (option.tag is Array and option.tag.has(tag)) or (option.tag is String and option.tag == tag):
			target_script = option.script

			if option.tag is Array:
				tag_properties = option.tag_properties.get(tag, {})
			else:
				tag_properties = option.tag_properties

			tag_auto_param_pass = option.get("tag_auto_param_pass", {})

			break

	for pass_property in tag_auto_param_pass:
		var pass_value: Variant = tag_auto_param_pass[pass_property]
		tag_properties[pass_property] = pass_value

	return {
		"script":target_script, 
		"tag_properties": tag_properties ,
		"tag_auto_properties" : tag_auto_param_pass
		}
