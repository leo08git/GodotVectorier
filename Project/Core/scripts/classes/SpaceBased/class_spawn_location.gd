@tool
## A class to represent an ingame level model
extends ClassFactor
class_name ClassSpawnLocation

@export_tool_button("Create model") var tb_cm = _create_model
## Quickly link to a model spawn name (i dont know why i did this but i did)
@export var link_model: ClassModel = null:
	set(value):
		if value and value.attributes.has("BirthSpawn"):
			spawn_id = value.attributes["BirthSpawn"]
		else:
			printerr("The target spawn doesn't have a BirthSpawn key, ignoring.")

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
	model_node.load_player_preset.call()
	model_node.attributes["BirthSpawn"] = name
	model_node.name = name + "_model"
	link_model = model_node
