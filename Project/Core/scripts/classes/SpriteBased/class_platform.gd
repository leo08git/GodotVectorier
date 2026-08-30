@tool
extends ClassFactor
class_name ClassPlatform

func get_xml_node() -> XMLNode:
	var pos = Helper.get_class_position(self)
	var size = Helper.get_class_dimensions(self)

	var reqattributes = {
		"X":pos.x, 
		"Y":pos.y, 
		"Width":size.x, 
		"Height":size.y}
	reqattributes.merge(attributes, true)

	return XMLNode.new("Platform", reqattributes, true)
