@tool
extends XMLDataRes
class_name TransformMoveInterval

@export var duration_frames: int = 0
@export var delay: float = 0.0

@export var start := Vector2()
@export var support := Vector2()
@export var finish := Vector2()

func get_xml(...data: Array) -> XMLNode:
	var node = XMLNode.new(
		"MoveInterval", {
			"Number":data[0] ,
			"FramesToMove":duration_frames ,
			"Delay":delay}
	)

	var x1 = XMLNode.new("Point", {"X":start.x , "Y":start.y, "Name": "Start"} , true)
	var x2 = XMLNode.new("Point", {"X":support.x , "Y":support.y, "Name": "Support"} , true)
	var x3 = XMLNode.new("Point", {"X":finish.x , "Y":finish.y, "Name": "Finish"} , true)

	node.children.append(x1)
	node.children.append(x2)
	node.children.append(x3)

	return node
