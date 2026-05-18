@tool
extends Node2D
## Level root, representing the current level being edited. The autoload tracks if you're editing this root or another root when switching between scenes.
class_name LevelRoot

enum DzipToolActions {decompile, compile}
var _initialized: bool = false

var _processed_level_name: String = ""
var _processed_thumbnail_path: String = ""

#region Actions
@export_group("Actions")
@export_tool_button("Refresh editor button") var toolbutton_refresheditorbuttons = EditorMenuHandler._refresh_button
@export_tool_button("Compile and save level to game") var toolbutton_buildmap = Helper.LevelHandler.compile_map.bind(self, false, true)
@export_tool_button("Compile & copy level content") var toolbutton_compilemap = Helper.LevelHandler.compile_map.bind(self, true, false)

#endregion


#region Level settings
@export_group("Level settings")
## Path to an image to use as the thumbnail; if empty, doesn't change anything.[br]
## [i]Normal thumbnail resolution: 512x340
@export_global_file("*.png") var level_thumbnail_path: String
## Displayed title. If empty, does not change anything.
@export var level_name: String
## Max coin objects on this level
@export var max_coins: int = 40
## A music file, we'll be getting only the name.
@export var music_name := "music_dinamic"
@export var music_volume := 0.3
## Level sets, only useful if you're using the [ClassObjectPrefab] class.
@export var sets: Dictionary[String, String] = {}

@export_enum(
	# DOWNTOWN STORY (01-11)
	"DOWNTOWN_STORY_01", "DOWNTOWN_STORY_02", "DOWNTOWN_STORY_03", "DOWNTOWN_STORY_04", "DOWNTOWN_STORY_05",
	"DOWNTOWN_STORY_06", "DOWNTOWN_STORY_07", "DOWNTOWN_STORY_08", "DOWNTOWN_STORY_09", "DOWNTOWN_STORY_10",
	"DOWNTOWN_STORY_11",
	
	# DOWNTOWN BONUS (01-09)
	"DOWNTOWN_BONUS_01", "DOWNTOWN_BONUS_02", "DOWNTOWN_BONUS_03", "DOWNTOWN_BONUS_04", "DOWNTOWN_BONUS_05",
	"DOWNTOWN_BONUS_06", "DOWNTOWN_BONUS_07", "DOWNTOWN_BONUS_08", "DOWNTOWN_BONUS_09",
	
	# CONSTRUCTION STORY (01-11)
	"CONSTRUCTION_STORY_01", "CONSTRUCTION_STORY_02", "CONSTRUCTION_STORY_03", "CONSTRUCTION_STORY_04",
	"CONSTRUCTION_STORY_05", "CONSTRUCTION_STORY_06", "CONSTRUCTION_STORY_07", "CONSTRUCTION_STORY_08",
	"CONSTRUCTION_STORY_09", "CONSTRUCTION_STORY_10", "CONSTRUCTION_STORY_11",
	
	# CONSTRUCTION BONUS (01-09)
	"CONSTRUCTION_BONUS_01", "CONSTRUCTION_BONUS_02", "CONSTRUCTION_BONUS_03", "CONSTRUCTION_BONUS_04",
	"CONSTRUCTION_BONUS_05", "CONSTRUCTION_BONUS_06", "CONSTRUCTION_BONUS_07", "CONSTRUCTION_BONUS_08",
	"CONSTRUCTION_BONUS_09",
	
	# TECHPARK STORY (01-11)
	"TECHPARK_STORY_01", "TECHPARK_STORY_02", "TECHPARK_STORY_03", "TECHPARK_STORY_04", "TECHPARK_STORY_05",
	"TECHPARK_STORY_06", "TECHPARK_STORY_07", "TECHPARK_STORY_08", "TECHPARK_STORY_09", "TECHPARK_STORY_10",
	"TECHPARK_STORY_11",
	
	# TECHPARK BONUS (01-09)
	"TECHPARK_BONUS_01", "TECHPARK_BONUS_02", "TECHPARK_BONUS_03", "TECHPARK_BONUS_04", "TECHPARK_BONUS_05",
	"TECHPARK_BONUS_06", "TECHPARK_BONUS_07", "TECHPARK_BONUS_08", "TECHPARK_BONUS_09"
) var override_this_level: String = "DOWNTOWN_STORY_01"

#endregion

#region Tools
@export_group("Tools")

#region dzip
@export_subgroup("Dzip")
## Path to folder or dz file.
@export var dzip_input: String = ""
@export var dzip_action: DzipToolActions
@export_tool_button("Execute") var toolbutton_dzip = EditorDzHandler.dzip_execute
#endregion

#region Editor QOL
@export_subgroup("Editor Quality Of Life")
## If true, whenever a [Sprite2D] is created, automatically set the script to the image class script.
@export var et_sprite2d_script_set: bool = true
## Automatically set sprite2D's pivot to top left when starting - Recommended.
@export var et_sprite2d_fix_pivot: bool = true
#endregion
#endregion

func _ready() -> void:
	print("Awaiting some seconds before initializing node processing...")
	child_entered_tree.connect(_on_child_entered_tree)
	await get_tree().create_timer(5.0).timeout
	_initialized = true
	print("Initialized node processing.")

func _on_child_entered_tree(node: Node) -> void:
	if not _initialized: return
	if node.has_meta("_editor_processed"): return
	if node.has_meta("qol_excluded"): return

	if et_sprite2d_fix_pivot and node is Sprite2D and node.texture:
		node.centered = false
		await get_tree().process_frame
		node.global_position -= (node.scale * node.texture.get_size()) / 2

	if et_sprite2d_script_set and node is Sprite2D and node.get_script() == null:
		node.set_script(preload("uid://b8ywmahn8mr4h"))

	node.set_meta("_editor_processed", 1)
