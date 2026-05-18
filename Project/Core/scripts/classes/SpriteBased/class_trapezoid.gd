@tool
extends ClassFactor
class_name ClassTrapezoid

enum types {upwards, downwards}

@export var trapezoid_type: types = types.upwards:
	set(value):
		trapezoid_type = value
		_type_changed.call_deferred()

func get_xml_node() -> XMLNode:
	var pos = Helper.get_class_position(self)
	var size = get("global_transform").get_scale() * get("texture").get_size()
	var req_attributes = {
		"X":pos.x, 
		"Y":pos.y, 
		"Width":size.x, 
		"Height": 1 if trapezoid_type == 0 else size.y,
		"Height1": size.y if trapezoid_type == 0 else 1,
		"Type" : trapezoid_type + 1}
	req_attributes.merge(attributes, true)

	return XMLNode.new("Trapezoid", req_attributes, true)

func _type_changed() -> void:
	set("flip_h", 1 if trapezoid_type == types.downwards else 0)
	var dimensions: Vector2 = get("texture").get_size()
	if trapezoid_type == types.downwards:
		set("offset", Vector2(0, 0))
	else:
		set("offset", Vector2(0, -dimensions.y))
