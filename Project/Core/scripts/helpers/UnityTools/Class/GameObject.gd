extends UnityTools
class_name UnityGameObject

var data: Dictionary

var children: Array[UnityGameObject] = []
var transform: UnityComponentTransform
var components: Array[UnityComponent] = []

static func build_from_dictionary(dic: Dictionary) -> UnityGameObject:
	var obj = UnityGameObject.new()
	obj.data = dic

	return obj
