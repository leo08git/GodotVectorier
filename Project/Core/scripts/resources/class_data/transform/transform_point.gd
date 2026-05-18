@tool
extends XMLDataRes
class_name TransformMoveIntervalPoint

@export var v: Vector2 = Vector2()

func get_xml(...data: Array) -> XMLNode:
	return XMLNode.new(
		"Point" ,
		{"X":v.x,"Y":v.y} , true
)
