@tool
extends Resource
class_name VectorierButtonTemplatesHolder

@export var is_submenu: bool = false
@export var children: Array[VectorierButtonTemplatesHolder]

@export var template_name: String
@export_multiline() var template_tooltip: String
@export var template_script: GDScript
