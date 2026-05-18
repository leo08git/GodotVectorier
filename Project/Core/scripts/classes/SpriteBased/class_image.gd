@tool
extends ClassFactor
class_name ClassImage
const PLATFORM = preload("uid://cwal0qfn1frnq")
const TRAPEZOID = preload("uid://bw5v4qobjrvt8")

@export_tool_button("Create collision") var toolbutton_create_platform = _create_platform
@export_tool_button("Create slope") var toolbutton_create_trapezoid = _create_trapezoid

func get_xml_node() -> XMLNode:
	var pos: Vector2 = Helper.get_class_position(self)
	var size: Vector2 = get("global_transform").get_scale() * get("texture").get_size()
	var req_attrs = {
			"X":pos.x, 
			"Y":pos.y, 
			"Width":size.x, 
			"Height":size.y,
			"ClassName":get("texture").resource_path.get_file().get_slice("." , 0)}
	req_attrs.merge(attributes, true)
	var node := XMLNode.new("Image", req_attrs, true)

	if not is_zero_approx(get("global_rotation")):
		node.standalone = false
		var properties := XMLNode.new("Properties")
		var _static := XMLNode.new("Static")
		var matrix := XMLNode.new("Matrix", {}, true)

		var t: Transform2D = get("global_transform")
		var angle: float = t.get_rotation()
		var A: float =  size.x * cos(angle)
		var B: float =  size.x * sin(angle)
		var C: float = -size.y * sin(angle)
		var D: float =  size.y * cos(angle)

		matrix.attributes = {
			"A" : A ,
			"B" : B ,
			"C" : C ,
			"D" : D ,
			"Tx" : 0 ,
			"Ty" : 0 ,
		}



		_static.children.append(matrix)
		properties.children.append(_static)
		node.children.append(properties)

	return node

func _create_platform() -> void:
	var ins = PLATFORM.instantiate()
	Helper.add_node(ins, self, null, true)
	ins.scale = get("texture").get_size() / ins.texture.get_size()

func _create_trapezoid() -> void:
	var ins = TRAPEZOID.instantiate()
	Helper.add_node(ins, get_parent(), null, true)
	get_parent().move_child(ins, get_index() + 1)
	ins.position = get("position")
