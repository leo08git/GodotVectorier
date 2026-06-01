@tool
## A class to represent an ingame level model
extends ClassFactor
class_name ClassModelSpawn

@export_tool_button("Create model") var tb_cm = _create_model

@export var spawn_id: String = ""
@export var spawn_animation: String = "JumpOff|18"

func get_xml_node() -> XMLNode:
	var pos = Helper.get_class_position(self)
	var size = get("scale") * get("texture").get_size()

	var req_attributes = {
		"X":pos.x ,
		"Y":pos.y ,
		"Width":size.x ,
		"Height":size.y ,
		"Name":spawn_id ,
		"Animation":spawn_animation}

	req_attributes.merge(attributes, true)

	return XMLNode.new("Spawn", req_attributes, true)

func _create_model() -> void:
	var model_node = ClassModel.new()
	Helper.add_node(model_node, self)
	model_node._load_preset("Player")
	model_node.attributes["BirthSpawn"] = name
	model_node.name = name + "_model"
	model_node.LinkedSpawnPoint = self
	spawn_id = model_node.attributes["BirthSpawn"]

func _ClassInitiate() -> void:
	if get_class() == "Sprite2D":
		var dimensions: Vector2 = get("scale") * get("texture").get_size()
		set_indexed("offset:y", -dimensions.y / 2)
