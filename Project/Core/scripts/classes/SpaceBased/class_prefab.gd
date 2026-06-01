@tool
extends ClassFactor
class_name ClassPrefab

@export var prefab_name: String

func get_xml_node() -> XMLNode:
	var pos: Vector2 = Helper.get_class_position(self)
	return XMLNode.new(
		"Object" ,
		{"X" : pos.x , "Y" : pos.y , "Name" : prefab_name} ,
		true
	)
