@tool
extends ClassFactor
class_name ClassImage
const PLATFORM = preload("uid://cwal0qfn1frnq")
const TRAPEZOID = preload("uid://bw5v4qobjrvt8")

@export_tool_button("Create collision") var toolbutton_create_platform = _create_platform
@export_tool_button("To TextureRect") var toolbutton_torect = _to_texturerect

func get_xml_node() -> XMLNode:
	var pos: Vector2 = Helper.get_class_position(self)
	var imgsize: Vector2 = Helper.get_class_dimensions(self)
	var req_attrs = {
			"X":pos.x, 
			"Y":pos.y, 
			"Width":imgsize.x, 
			"Height":imgsize.y,
			"ClassName":get("texture").resource_path.get_file().get_slice("." , 0)}
	req_attrs.merge(attributes, true)
	var node := XMLNode.new("Image", req_attrs, true)

	if get_class() == "Sprite2D" and not is_zero_approx(get("global_rotation")):
		node.standalone = false
		var properties := XMLNode.new("Properties")
		var _static := XMLNode.new("Static")
		var matrix := XMLNode.new("Matrix", {}, true)

		var t: Transform2D = get("global_transform")
		var angle: float = t.get_rotation()
		var A: float =  imgsize.x * cos(angle)
		var B: float =  imgsize.x * sin(angle)
		var C: float = -imgsize.y * sin(angle)
		var D: float =  imgsize.y * cos(angle)

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

func _to_texturerect() -> void:
	var rect = TextureRect.new()
	Helper.add_node(rect, get_parent())
	rect.texture = get("texture")
	rect.position = get("position")
	rect.scale = get("scale")
	rect.size = get("texture").get_size()
	rect.name = get("texture").resource_path.get_file().get_slice(".", 0) + "_rect"
	(get_parent() as Node).move_child(rect, get_index() + 1)
	queue_free()
