@tool
extends ClassFactor
class_name ClassArea

@export var area_name: String

func get_xml_node() -> XMLNode:
	var pos = Helper.get_class_position(self)
	var size = Helper.get_class_dimensions(self)
	var req_attributes = {
		"X":pos.x, 
		"Y":pos.y, 
		"Width":size.x, 
		"Height":size.y ,
		"Name" : area_name}

	attributes.merge(req_attributes, true)
	return XMLNode.new("Area", req_attributes, true)
