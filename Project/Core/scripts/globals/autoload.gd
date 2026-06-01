@tool
extends Node
## Emitted before the level is sorted (moved to the root). On this stage, the [code]_TrackContent[/code] key is accessible and has the { factor : [nodes] } structure for easier modifying.
## To make changes to level content factors, access the [code]_TrackContent[/code] key.[br]
## E.g: [codeblock]
##func _ready():
##	LevelPreSort.connect(RemoveAllBackdrop)
##
##func RemoveAllBackdrop(structure: Dictionary, root: XMLNode):
##	structure._TrackContent.get("0.5").clear()[/codeblock][br]
## When compiling a level, all backdrop-tagged images will be excluded.
signal LevelPreSort(content: Dictionary, root: XMLNode)
## Emitted after a level is parsed and sorted, the [code]_TrackContent[/code] key no longer exists.
signal LevelPosSort(root: XMLNode)

var level: LevelRoot = null
var settings: Dictionary = {}

# update the current edited level
func _physics_process(_delta: float) -> void:
	var o = EditorInterface.get_edited_scene_root()
	if o is LevelRoot:
		level = o
