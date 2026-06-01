@tool
extends Sprite2D
class_name AutoPlatform

const TextureSegmentSize: float = 128
const segmentsXMargin: float = 2.5
const segmentsYMargin: float = 2.5
const SegmentsOffset: int = 2

@warning_ignore("unused_private_class_variable")
@export var _build = false:
	set(value):
		if !value: return
		build()

## When compiling a level, autoplatforms that weren't built will be built and then deleted if said autoplatform has this setting off - Perfomance costy
@export var IgnoredByCompiler: bool = true

@export_group("Textures")
@export var texture_center: Texture2D
@export var textures_top_left: Array[Texture2D] = []
@export var textures_top_right: Array[Texture2D] = []
@export var textures_bottom_left: Array[Texture2D] = []
@export var textures_bottom_right: Array[Texture2D] = []
@export var textures_floor: Array[Texture2D] = []
@export var textures_ceiling: Array[Texture2D] = []
@export var textures_wall_left: Array[Texture2D] = []
@export var textures_wall_right: Array[Texture2D] = []

func _init() -> void:
	set_meta("qol_excluded", 1)

func _process(_delta: float) -> void:
	global_position = global_position.snappedf(TextureSegmentSize)
	scale = scale.snappedf(TextureSegmentSize)
	rotation = 0.0

func build(MaxIterations: int = -1) -> void:
	var h_segments: int = clamp((scale.x / TextureSegmentSize) - SegmentsOffset, 0, INF)
	var v_segments: int = clamp((scale.y / TextureSegmentSize) - SegmentsOffset, 0, INF)

	EditorInterface.get_selection().remove_node(self)

	var parent := Node2D.new()
	Helper.add_node(parent, get_parent())
	parent.name = "Platform"
	parent.global_position = global_position

	var Edge: Vector2 = scale - Vector2(TextureSegmentSize, TextureSegmentSize)

	var top_left := _create_sprite(
		global_position, 
		textures_top_left.pick_random(), parent)

	_create_sprite( # top right
		global_position + Vector2(Edge.x, 0), 
		textures_top_right.pick_random(), parent)

	_create_sprite( # bottom left
		global_position + Vector2(0, Edge.y), 
		textures_bottom_left.pick_random(), parent)

	var bottom_right := _create_sprite(
		global_position + Edge, 
		textures_bottom_right.pick_random(), parent)

	const FloorSclMargin := Vector2(0.1,0)
	const WallSclMargin := Vector2(0,0.1)
# what am i doing, why is margin everywhere - leo08

	var IterationIdx: int = 0

	for segment_idx in h_segments: # floor
		_create_sprite(
			global_position + CalculateSegmentOffsetMultiplier(segment_idx, true), 
			textures_floor.pick_random(), parent, FloorSclMargin)
		IterationIdx += 1
		if MaxIterations != -1 and IterationIdx >= MaxIterations:
			IterationIdx = 0
			await get_tree().process_frame

	for segment_idx in v_segments: # left wall
		_create_sprite(
			global_position + CalculateSegmentOffsetMultiplier(segment_idx, false), 
			textures_wall_left.pick_random(), parent, WallSclMargin)
		IterationIdx += 1
		if MaxIterations != -1 and IterationIdx >= MaxIterations:
			IterationIdx = 0
			await get_tree().process_frame

	for segment_idx in v_segments: # right wall
		_create_sprite(
			global_position + CalculateSegmentOffsetMultiplier(segment_idx, false) + Vector2(Edge.x, 0.0), 
			textures_wall_right.pick_random(), parent, WallSclMargin)
		IterationIdx += 1
		if MaxIterations != -1 and IterationIdx >= MaxIterations:
			IterationIdx = 0
			await get_tree().process_frame

	const fillHeightMargin: float = 0.28
	var fill_position: Vector2 = top_left.global_position + ((top_left.texture.get_size() / 2) * top_left.scale)
	var fill_scale: Vector2 = ((bottom_right.global_position - top_left.global_position) / texture_center.get_size()) + Vector2(0,bottom_right.scale.y + fillHeightMargin)
	var fill := _create_sprite(
			fill_position, 
			texture_center, parent)
	fill.scale = fill_scale

	var platform_texture: Texture2D = preload("uid://br756h62fspkb")
	var platform_script: GDScript = preload("uid://cyjvkka35b16s")

	var platform := _create_sprite(
			top_left.global_position, 
			platform_texture, parent)
	platform.scale = scale / platform.texture.get_size()
	platform.set_script(platform_script)


	queue_free.call_deferred()
	return


func CalculateSegmentOffsetMultiplier(segment_index: int, x_axis: bool) -> Vector2:
	return Vector2(
		((TextureSegmentSize * float(segment_index)) + TextureSegmentSize - segmentsXMargin) if x_axis else 1.0, 
		((TextureSegmentSize * float(segment_index)) + TextureSegmentSize - segmentsYMargin) if not x_axis else 1.0)

func _create_sprite(pos: Vector2, _texture: Texture2D, parent: Node, scale_margin := Vector2(), _scale: Vector2 = Vector2.ONE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _texture
	sprite.centered = false
	Helper.add_node(sprite, parent)
	sprite.global_position = pos - scale_margin
	sprite.scale = (Vector2(TextureSegmentSize, TextureSegmentSize) / _texture.get_size()) + scale_margin
	sprite.set_script(preload("uid://b8ywmahn8mr4h"))
	sprite.name = (_texture.resource_path.get_file().get_slice(".", 0))

	return sprite
