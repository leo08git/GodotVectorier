@tool
extends Node2D
## Not important for GodotVectorier usage and can be deleted aswell with the _dev folder. Dont judge my poor coding.
## btw this had a LOT of iterations to become what it is, so, you know... appreciate pls :3

const BlacklistedAttributes = [
	"X", "Y", "Width", "Height", "Height1", "NativeX", "NativeY", "Name"
]

@export_tool_button("Import") var tb_import = import
@export_file() var file_path: String
@export var object_per_frame: int = 15
## debugonly
@export var owner_is_tree: bool = false
@export_dir var other_objects_path: String

var object: Node2D = null
var requested_objects: Array[Dictionary] = []
#var requested_objects: Dictionary[Node, PackedStringArray] = {}


var objects: Array[Node2D]

var parsed_index: int = 0
var parse_final_index: int

func import() -> void:
	requested_objects = []
	objects = []
	object = null
	parsed_index = 0
	var root = XML.parse_file(file_path).root
	var all = root.get_all_children()
	parse_final_index = all.size() - 1

	for node in all:
		parse_node(node)

		parsed_index += 1
		if parsed_index > object_per_frame:
			parsed_index = 0
			await get_tree().process_frame

	pos_parse()

func parse_node(node: XMLNode) -> void:
	var instance: Node = Helper.xml_to_instance(node, true)

	if instance is ClassBase:
		if object:
			Helper.add_node(instance, object, null if owner_is_tree else object)
		if (instance is Node2D):
			apply_transform_attributes(instance, node)

		for attribute in node.attributes:
			if not BlacklistedAttributes.has(attribute):
				instance.attributes[attribute] = node.attributes[attribute]

	elif instance and instance.has_meta("is_object"):
		instance.remove_meta("is_object")
		Helper.add_node(instance, self, null if owner_is_tree else self)
		apply_transform_attributes(instance, node)
		object = instance
		objects.append(instance)


## Object that is inside another object
	elif node.name == "Object" and node.standalone and object:
		requested_objects.append({
			"target" : node.attributes["Name"],
			"requester" : object ,
			"xml" : node
		})
		return

func pos_parse() -> void:
	var other_objects_paths: PackedStringArray = []
	Helper.seek_files(other_objects_path, other_objects_paths, &"scn")

	var find_object = func(n: String) -> Node2D: 
		for i in objects: 
			if i.name == n:
				return i
		for candidate in other_objects_paths:
			if (candidate.get_file().trim_suffix(".scn")) == n:
				var instance = load(candidate).instantiate()
				Helper.add_node(instance, self, null if owner_is_tree else self)
				instance.set_meta("fscene", 1)
				return instance
		return null

	if not requested_objects.is_empty():
		for request in requested_objects:
			var obj_ins: Node2D = find_object.call(request["target"])
			var requester: Node = request["requester"]
			var xml: XMLNode = request["xml"]

			var dupli = obj_ins.duplicate()
			Helper.add_node(dupli, requester, requester)
			apply_transform_attributes(dupli, xml)

			parsed_index += 1
			if parsed_index > object_per_frame:
				parsed_index = 0
				await get_tree().process_frame

	for obj in objects:
		var scn: PackedScene = Helper.node_to_scene(obj, true)
		ResourceSaver.save(scn, "res://user/Pack/ObjectPack/ObjectsConstruction/%s.scn" % obj.name)
		obj.queue_free()

		parsed_index += 1
		if parsed_index > object_per_frame:
			parsed_index = 0
			await get_tree().process_frame

func apply_transform_attributes(ins: Node, node: XMLNode) -> void:
	if node.attributes.has("X"): ins.position.x = float(node.attributes.X)
	if node.attributes.has("Y"): ins.position.y = float(node.attributes.Y)
	if node.attributes.has("Width"): ins.scale.x = float(node.attributes.Width) / ins.texture.get_width()
	if node.attributes.has("Height"): ins.scale.y = float(node.attributes.Height) / ins.texture.get_height()
