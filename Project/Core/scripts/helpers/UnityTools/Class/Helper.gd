extends UnityTools
class_name UnityHelper

static func build_vector3(vector: Dictionary) -> Vector3:
	return Vector3(vector.x, vector.y, vector.z)

static func build_color(data: Dictionary) -> Color:
	return Color(
		data.r, data.g, data.b, data.a
	)


static func build_vector2(vector: Dictionary) -> Vector2:
	return Vector2(vector.x, vector.y)

static func build_quaternion(quar: Dictionary) -> Quaternion:
	return Quaternion(
		quar.x ,
		-quar.y ,
		quar.z ,
		-quar.w
	)

## Gets all ids from a scene/prefab file.
static func get_scene_fileids(scene_string: String) -> PackedStringArray:
	var ids: PackedStringArray = []

	var regex := RegEx.create_from_string(r"--- !u!(\d+) &(\d+)( stripped)?")

	for line: String in scene_string.split("\n"):
		var result = regex.search(line)

		if result:
			var id = result.get_string(2)
			#if not (result.get_string(3).strip_edges()).is_empty(): STRIPPED IDENTIFIER, IDK.
			#	id += "_s"
			ids.append(id)

	return ids

static func evaluate_gameobject_class(object: UnityGameObject) -> String:

	var sprite_renderer_component: UnityComponentSpriteRenderer = null
	var tag = object.data.get("m_TagString", &"")
	const ImageTags: PackedStringArray = [
		"Backdrop", "Image", "Top Image"
	]

	for component in object.components:
		if component is UnityComponentSpriteRenderer: sprite_renderer_component = component

	var PredictOptions: Array[Dictionary] = [

		{
					"type" : "Node2D" ,
					"condition" : is_instance_valid(object.transform) ,
					"priority" : 0
		} ,

		{
					"type" : "Sprite2D" ,
					"condition" : (is_instance_valid(sprite_renderer_component) and is_instance_valid(object.transform) or ImageTags.has(tag)) ,
					"priority" : 1
		}

		]

	var type_candidate: Dictionary = {}
	for prediction: Dictionary in PredictOptions:
		if prediction.condition == false: continue
		if (type_candidate.is_empty() or prediction.priority > type_candidate.priority):
			type_candidate = prediction

	return type_candidate.get("type", "")

## Tries transforming a [UnityGameObject] into a node, if it fails, returns null.
static func obj_to_node(obj: UnityGameObject) -> Node: 
	var nodeclass = evaluate_gameobject_class(obj)
	if nodeclass.is_empty(): 
		printerr("[UnityHelper, obj_to_node] Evaluated object class came as empty!")
		return null
	var instance = ClassDB.instantiate(nodeclass)
	if not instance: return null

	for component: UnityComponent in obj.components:
		component.apply_data(instance)

	return instance
