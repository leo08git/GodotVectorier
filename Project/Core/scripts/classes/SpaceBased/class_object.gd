@tool
extends ClassChildContainer
class_name ClassObject

func get_xml_node() -> XMLNode:
	var pos: Vector2 = Helper.get_class_position(self)

	return XMLNode.new("Object", {
		"X" : pos.x,
		"Y" : pos.y
	}, true if get_child_count() == 0 else false)
