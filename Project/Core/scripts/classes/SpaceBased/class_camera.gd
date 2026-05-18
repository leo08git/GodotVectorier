@tool
extends ClassFactor
class_name ClassCamera

func get_xml_node() -> XMLNode:
	var pos: Vector2 = Helper.get_class_position(self)
	var required_attrs = {
			"X":pos.x, 
			"Y":pos.y}
	required_attrs.merge(attributes, true)
	return XMLNode.new("Camera", required_attrs, true)
