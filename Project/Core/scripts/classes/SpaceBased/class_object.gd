@tool
extends ClassFactor
## Container class that holds all objects inside itself, includes position x and y as attributes.
class_name ClassObject

func get_xml_node() -> XMLNode:
	var pos: Vector2 = Helper.get_class_position(self)
	var node = XMLNode.new("Object", {
		"X" : pos.x,
		"Y" : pos.y}, 
		true if get_child_count() == 0 else false)
	var content = XMLNode.new("Content")

	for xml in Helper.tree_to_xml(self):
		content.append(xml)
	if not content.children.is_empty():
		node.append(content)

	return node
