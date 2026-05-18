@tool
## A class to represent an ingame level model, does nothing on its own besides adding a model to the XML. See [ClassSpawn]

extends ClassBase
class_name ClassModel
enum presets {PLAYER , HUNTER , HELPER , REVOLUTION_GIRL}
enum modes {
	HUNTER_MODE, ## Only shows up in hunter mode when playing this level 
	COMMON_MODE ## Only shows up in classic mode when playing this level
}

var presets_dic = {
	presets.PLAYER : {"Name" = "Player" ,"Type" = 1 ,"Color" = Color.BLACK ,"BirthSpawn" = "PlayerSpawn" ,"AI" = 0 ,"Time" = 0.0 } ,
	presets.HUNTER : {"Name" = "Hunter" ,"Type" = 0 ,"Color" = Color.BLACK ,"BirthSpawn" = "HunterSpawn" ,"AI" = 1 ,"Time" = 0.1 , "Skins" = "Hunter" , "Murders"= "Player|Helper" , "Arrests"="Player"  , "Icon"= 1 } ,
	presets.HELPER : {"Name"="Helper" , "Type"="0" , "Color"=Color.BLACK , "BirthSpawn"="HelperSpawn" , "AI"=2 , "Time"=0.0 , "Skins"="helper|shirt|cap" , "LifeTime"=5.0} ,
	presets.REVOLUTION_GIRL : {"Name"="RevolutionGirl" , "Type"=0 , "Color"=Color.BLACK ,  "BirthSpawn"="RevolutionGirlSpawn" ,  "Time"=0.0 ,  "AI"=3 , "Skins"="revolution_girl"}
}

## What mode this model should be present in when exporting
@export var mode := modes.COMMON_MODE

## Preset buttons
@export_tool_button("Load player preset" , "CharacterBody2D") var load_player_preset = func(): _load_preset(presets.PLAYER)
@export_tool_button("Load hunter preset" , "CharacterBody2D") var load_hunter_preset = func(): _load_preset(presets.HUNTER)
@export_tool_button("Load helper preset" , "CharacterBody2D") var load_helper_preset = func(): _load_preset(presets.HELPER)
@export_tool_button("Load revolution girl preset" , "CharacterBody2D") var load_revgirl_preset = func(): _load_preset(presets.REVOLUTION_GIRL)

func _load_preset(preset: presets) -> void:
	var preset_dic: Dictionary = presets_dic[preset]
	attributes = preset_dic
	property_list_changed.emit.call_deferred()

func get_xml_node() -> XMLNode:
	var required_attrs = {"Name" : "UnnamedModel" , "Type" : 0 , "Color" : "0"}
	required_attrs.merge(attributes, true)
	var node = XMLNode.new("Model", required_attrs, true)
	if required_attrs.Color is Color:
		node.attributes.Color = "0" if Color().is_equal_approx(required_attrs.Color) else "#%s" % str((node.attributes.Color as Color).to_html(false))

	return node
