@tool
extends ClassBase
## A class to represent an ingame level model, does nothing on its own besides adding a model to the XML. See [ClassModelSpawn]
class_name ClassModel

## Any changes made to the "BirthSpawn" attribute will update this spawn point
@export var LinkedSpawnPoint: ClassModelSpawn:
	set(value):
		LinkedSpawnPoint = value
		if value and attributes.has("BirthSpawn"):
			value.spawn_id = attributes.get("BirthSpawn")
## If enabled, this model only spawns when playing on hunter mode.
@export var HunterMode: bool = false

var presets_dic = {
	"Player" : {"Name" = "Player" ,"Type" = 1 ,"Color" = Color.BLACK ,"BirthSpawn" = "PlayerSpawn" ,"AI" = 0 ,"Time" = 0.0, "Trick" = "1", "Item" = "1", "Victory" = "1", "Lose" = "1"} ,
	"Hunter" : {"Name" = "Hunter" ,"Type" = 0 ,"Color" = Color.BLACK ,"BirthSpawn" = "HunterSpawn" ,"AI" = 1 ,"Time" = 0.1 , "Skins" = "Hunter" , "Murders"= "Player|Helper" , "Arrests"="Player"  , "Icon"= 1 } ,
	"Helper" : {"Name"="Helper" , "Type"="0" , "Color"=Color.BLACK , "BirthSpawn"="HelperSpawn" , "AI"=2 , "Time"=0.0 , "Skins"="helper|shirt|cap" , "LifeTime"=5.0} ,
	"Revolution Girl" : {"Name"="RevolutionGirl" , "Type"=0 , "Color"=Color.BLACK ,  "BirthSpawn"="RevolutionGirlSpawn" ,  "Time"=0.0 ,  "AI"=3 , "Skins"="revolution_girl"}
}

func _load_preset(preset: String) -> void:
	if not presets_dic.has(preset): return
	var preset_dic: Dictionary = presets_dic[preset].duplicate()
	attributes = preset_dic
	call_deferred("notify_property_list_changed")

func get_xml_node() -> XMLNode:
	var required_attrs = {"Name" : "UnnamedModel" , "Type" : 0 , "Color" : "0"}
	required_attrs.merge(attributes, true)
	var node = XMLNode.new("Model", required_attrs, true)
	if required_attrs.Color is Color:
		node.attributes.Color = "0" if Color().is_equal_approx(required_attrs.Color) else "#%s" % str((node.attributes.Color as Color).to_html(false))

	return node

func _get_property_list() -> Array[Dictionary]:
	return [{
		"name" : "Load preset" ,
		"type" : TYPE_STRING ,
		"hint" : PROPERTY_HINT_ENUM ,
		"hint_string" : ",".join(presets_dic.keys())
	}]

func _set(property: StringName, value: Variant) -> bool:
	if property == "Load preset":
		_load_preset(value)
		return true
	return false

func _get(property: StringName) -> Variant:
	if property == "Load preset":
		return "Presets..."
	return null

func _attribute_changed(attribute: StringName, new_value: Variant) -> void:
	if attribute == "BirthSpawn" and is_instance_valid(LinkedSpawnPoint):
		LinkedSpawnPoint.spawn_id = new_value
