@tool
extends ClassObject
## Vector transform node.[br]
## Recommended node for such class: [Node2D]

class_name ClassTransform

@export_tool_button("Preview move") var tb_preview = transform_preview
@export_tool_button("Cancel preview") var tb_cancelpreview = cancel_preview
@export var transform_name: String
@export var move_intervals: Array[TransformMoveInterval]

@export_group("Quick interval")
## When true, registers the transform to calculate interval offset, and when toggled off goes back to that transform.
@export var quick_interval_mode: bool = false:
	set(value):
		quick_interval_mode = value
		if value == true:
			quick_interval_start_transform = get("transform")
		else:
			set("position", quick_interval_start_transform.get_origin())
			quick_interval_start_transform = Transform2D()
@export var quick_interval_frames: int = 65
@export var quick_interval_delay: float = 0
@export_range(0.0, 1.0, 0.01, "or_greater", "or_less") var quick_interval_support_multiplier: float = 0.5

@export_tool_button("Quick interval insert") var tb_qi = quick_interval

var quick_interval_start_transform: Transform2D

var start_transform: Transform2D
var previewing: bool = false
var cancel_preview_requested: bool = false

func quick_interval() -> void:
	if not quick_interval_mode: 
		push_warning("Enable quick interval mode.")
		return
	var index: int = move_intervals.size()
	var previous_index: int = index - 1 if index > 0 else -1
	var inter := TransformMoveInterval.new()

	inter.start = Vector2() if previous_index == -1 else move_intervals.get(previous_index).finish
	inter.finish = get("global_position") - quick_interval_start_transform.get_origin()
	inter.support = inter.finish * quick_interval_support_multiplier

	inter.duration_frames = quick_interval_frames
	inter.delay = quick_interval_delay

	move_intervals.append(inter)
	notify_property_list_changed.call_deferred()

func cancel_preview() -> void:
	if previewing:
		previewing = false
		cancel_preview_requested = true

func transform_preview() -> void: 
	if quick_interval_mode: printerr("Disable quick interval mode to preview."); return
	start_transform = get("transform")
	if previewing:
		EditorInterface.get_editor_toaster().push_toast("A preview is still running!", EditorToaster.SEVERITY_ERROR)
		return

	previewing = true

	var origin := start_transform.get_origin()

	for interval in move_intervals:
		if cancel_preview_requested: 
			set("transform", start_transform)
			cancel_preview_requested = false
			return
		await get_tree().create_timer(interval.delay).timeout

		var current_frame := 0

		while current_frame <= interval.duration_frames:
			if cancel_preview_requested: 
				set("transform", start_transform)
				cancel_preview_requested = false
				return
			var p0 := interval.start
			var p1 := interval.support
			var p2 := interval.finish

			var t := float(current_frame) / interval.duration_frames

			var point := Helper.quadratic_bezier(p0, p1, p2, t)

			set("global_position", origin + point)

			await get_tree().physics_frame
			current_frame += 1

	set("transform", start_transform)
	previewing = false

func get_xml_node() -> XMLNode:
	var parent_node: XMLNode = super.get_xml_node()
	var transformation_node: XMLNode = XMLNode.new("Transformation", {"Name":transform_name})
	var interval_content_node := XMLNode.new("Move")
	var properties_node: XMLNode

	if parent_node.has_child("Properties"):
		properties_node = parent_node.Properties
	else:
		properties_node = XMLNode.new("Properties")
		parent_node.children.append(properties_node)

	var dynamic_node := XMLNode.new("Dynamic")

	properties_node.children.append(dynamic_node)
	dynamic_node.children.append(transformation_node)
	transformation_node.children.append(interval_content_node)

	var interval_idx: int = 0
	for interval in move_intervals:
		interval_content_node.children.append(interval.get_xml(interval_idx))
		interval_idx += 1

	return parent_node

func _physics_process(delta: float) -> void:
	pass
