extends UnityComponent
class_name UnityComponentTransform

func apply_data(to: Node) -> void:
	if not to.is_inside_tree(): 
		await to.tree_entered

	to.position = get_position()
	to.rotation = get_rotation()
	to.scale = get_scale()


func get_position() -> Vector2:
	return (Vector2(
		data.m_LocalPosition.x ,
		-data.m_LocalPosition.y) * 100)

func get_rotation() -> float:
	return UnityHelper.build_quaternion(data.m_LocalRotation).get_angle()

func get_scale() -> Vector2:
	return UnityHelper.build_vector2(data.m_LocalScale)
