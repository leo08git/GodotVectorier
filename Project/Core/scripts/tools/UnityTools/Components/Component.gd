extends UnityTools
class_name UnityComponent

var data: Dictionary
var type: String
var fileid: StringName
var object: UnityGameObject
var scene: UnityScene

const COMPONENTS: Dictionary[String, GDScript] = {
	"Transform" : preload("uid://eyy28q1rg0f7") ,
	"SpriteRenderer" : preload("uid://ch5k2jq7hgqcb") ,
	"MonoBehaviour" : preload("uid://c2xo1ssouuc4o")}

## Used to build a component with a dictionary
static func build_from_dictionary(component_type: String , _data: Dictionary) -> UnityComponent:
	var comp: UnityComponent = null
	if not COMPONENTS.has(component_type): return null
	comp = (COMPONENTS.get(component_type) as GDScript).new()
	comp.type = component_type
	comp.data = _data

	return comp

## Override this method. Used to update the component data with a dictionary.
func update_data(_data: Dictionary) -> void:
	for property in _data:
		data.set(property, _data[property])

## Override this method. Applies necessary data to passed node.
func apply_data(_to: Node) -> void:
	pass
