@tool
extends Node
## Base class for all GodotVectorier classes.
class_name ClassBase

@export_tool_button("Preview attributes") var tb_pa = func(): 
	EditorInterface.get_editor_toaster().push_toast("Remember to empty it because those attributes will override generated ones!", EditorToaster.SEVERITY_INFO)
	attributes.merge(get_xml_node().attributes)
	notify_property_list_changed.call_deferred()

## If this class should be included in export
@export var enabled := true
## XML attributes, any entry here will override the required attributes created on the [method get_xml_node] function.
@export var attributes: Dictionary = {}:
	set(value):
		if attributes == value: return
		var previous_dictionary: Dictionary = attributes.duplicate()
		attributes = value

		for attribute in previous_dictionary:
			var previous = previous_dictionary.get(attribute)
			var new = attributes[attribute]

			if previous != new: 
				_attribute_changed(attribute, new)

func _change_class_request(new_class: String) -> void:
	var CLASS_TEMPLATES = load("uid://bbi7jlswl1wji")
	if !CLASS_TEMPLATES.templates.has(new_class): return
	var script: GDScript = CLASS_TEMPLATES.templates[new_class]
	set_script(script)
	_ClassInitiate()

	if new_class == "Trapezoid": (self as ClassTrapezoid)._type_changed.call_deferred()

## Used when compiling a level, creates different required attributes entries depending on the class.
func get_xml_node() -> XMLNode:
	return null

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	var CLASS_TEMPLATES = load("uid://bbi7jlswl1wji")
	var enum_list = CLASS_TEMPLATES.templates.keys()

	properties.append({
		"name":"Change class" ,
		"type":TYPE_STRING ,
		"hint":PROPERTY_HINT_ENUM ,
		"hint_string" : ",".join(enum_list)
	})

	return properties

func _get(property: StringName) -> Variant:
	if property == "Change class":
		return "Classes..."
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property == "Change class":
		_change_class_request(value)
		return true

	return false

func _attribute_changed(attribute: StringName, new_value: Variant) -> void:
	pass

func _ClassInitiate() -> void:
	pass
