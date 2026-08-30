@tool
extends Node
## Base class for all GodotVectorier classes.
class_name ClassBase
enum TargetModes {
## Default, will spawn on both common mode and hunter mode.
	ALL, 
## Will only spawn on common mode.
	CommonMode, 
## Will only spawn on hunter mode.
	HunterMode}
signal AttributeChanged(attribute: String, old_value: Variant, new_value: Variant)

@export_tool_button("Preview attributes") var tb_pa = func(): 
	EditorInterface.get_editor_toaster().push_toast("Remember to empty it because those attributes will override generated ones!", EditorToaster.SEVERITY_INFO)
	attributes.merge(get_xml_node().attributes)
	notify_property_list_changed.call_deferred()

## If this class should be included in export
@export var enabled := true
## On what game mode this object should spawn on.
@export var TargetMode: TargetModes = TargetModes.ALL
## XML attributes, any entry here will override the required attributes created on the [method get_xml_node] function.
@export var attributes: Dictionary = {}:
	set(new_dictionary):
		if attributes == new_dictionary: return
		var previous_dictionary: Dictionary = attributes.duplicate()
		attributes = new_dictionary

		for attribute in previous_dictionary:
			if not attributes.has(attribute): continue
			var previous = previous_dictionary.get(attribute)
			var new = attributes[attribute]

			if previous != new: 
				AttributeChanged.emit(attribute, previous, new)
				_attribute_changed(attribute, new)

@export_storage var CurrentClass: StringName = &"Base"

func _change_class_request(new_class: String) -> void:
	var CLASS_TEMPLATES = load("uid://bbi7jlswl1wji")
	if !CLASS_TEMPLATES.templates.has(new_class): return
	var script: GDScript = CLASS_TEMPLATES.templates[new_class]
	set_script(script)
	CurrentClass = new_class
	_class_initiate()

## Used when compiling a level, creates different required attributes entries depending on the class.
func get_xml_node() -> XMLNode:
	printerr("Getting XMLNode from a ClassBase instance (%s), please use a class that overrides this method!" % name)
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

func _attribute_changed(_attribute: StringName, _new_value: Variant) -> void:
	pass

## Called after the user changes class type.
func _class_initiate() -> void:
	pass
