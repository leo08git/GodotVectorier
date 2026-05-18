@tool
extends Node

const CMD_TEMPLATE = '<Init>
    <SetVariable Name="$Active" Value="1"/>
    <SetVariable Name="$AI" Value="%d" />
    <SetVariable Name="Flag1" Value="0"/>
</Init>
<Loop>
  <Events>
    <Enter/>
  </Events>
  <Actions>
    <Press Key="%s" Model="_$Model" />
  </Actions>
</Loop>
'

@onready var preview_panel: MeshInstance2D = $PreviewPanel
@onready var preview_arrow: Sprite2D = $PreviewPanel/PreviewArrow

@onready var template_donttouch: ClassTrigger = $Template_Donttouch
@export var processing: bool = false
@export var model: ClassModel

@export var jump_key: Key = KEY_UP
@export var slide_key: Key = KEY_DOWN
@export var left_key: Key = KEY_LEFT
@export var right_key: Key = KEY_RIGHT
@export var toggle_processing_key: Key = KEY_TAB

var holder: Node2D = null

func _ready() -> void:
	set_process_input(true)

var cooldown: float = 0.0
func _physics_process(delta: float) -> void:
	if (cooldown >= 0.0): cooldown -= delta
	if processing:
		preview_panel.global_position = template_donttouch.get_global_mouse_position()
	else:
		preview_panel.position = Vector2()
		preview_arrow.rotation = 0

	if processing and cooldown <= 0.0:
		if not model: return
		if Input.is_key_pressed(jump_key):
			cooldown = 0.1
			get_viewport().set_input_as_handled()
			generate_trigger("Up")
			preview_arrow.texture = preload("uid://krud5g6v86ma")
		if Input.is_key_pressed(slide_key):
			cooldown = 0.1
			get_viewport().set_input_as_handled()
			generate_trigger("Down")
			preview_arrow.texture = preload("uid://bshia3nifh67j")
		if Input.is_key_pressed(left_key):
			cooldown = 0.1
			get_viewport().set_input_as_handled()
			generate_trigger("Left")
			preview_arrow.texture = preload("uid://dt0380g508606")
		if Input.is_key_pressed(right_key):
			cooldown = 0.1
			get_viewport().set_input_as_handled()
			generate_trigger("Right")
			preview_arrow.texture = preload("uid://bpxcuv3wivvja")
	if Input.is_key_pressed(toggle_processing_key) and cooldown <= 0.0:
		cooldown = 0.1
		processing = not processing

func generate_trigger(arrow: String) -> void:
	if not is_instance_valid(holder): handle_holder()


	var d: ClassTrigger = template_donttouch.duplicate()
	Helper.add_node(d , holder, null, true)
	d.global_position = preview_panel.global_position - (preview_panel.global_transform.get_scale() / 2)
	d.Command = CMD_TEMPLATE % [model.attributes.get_or_add("AI", int(1)) , arrow]
	d.show()
	d.name = "Ai%dPathWay" % model.attributes.get_or_add("AI", int(1))

func handle_holder() -> void:
	var holdername = "AI%d_Pathway" % model.attributes.get_or_add("AI", int(1))

	if get_parent().has_node(holdername): 
		holder = get_parent().get_node(holdername)
	else:
		holder = Node2D.new()
		holder.name = holdername
		Helper.add_node(holder , get_parent(), null, true)
