@tool
extends Resource
class_name TriggerTemplates

@export var templates: Dictionary[String, String]

@export var new_template_name: String
@export_multiline() var new_template: String
@export_tool_button("Add template") var b = _add_template

func _add_template() -> void:
	templates.set(new_template_name, new_template)
	new_template_name = ""
	new_template = ""
	notify_property_list_changed.call_deferred()

func _edit_template(edit_template_name: String) -> void:
	var previously_empty: bool = \
		new_template_name.is_empty() and \
		new_template.is_empty()

	var v = templates.get(edit_template_name)
	if v == null or v.is_empty(): return
	if not previously_empty: _add_template()
	new_template_name = edit_template_name
	new_template = v
	templates.erase(edit_template_name)
	notify_property_list_changed.call_deferred()

func _duplicate_template(template_name: String) -> void:
	var previously_empty: bool = \
		new_template_name.is_empty() and \
		new_template.is_empty()

	var v = templates.get(template_name)
	if not v: return
	if v.is_empty(): return
	if not previously_empty: _add_template()
	new_template_name = template_name
	new_template = v
	notify_property_list_changed.call_deferred()

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	var enum_list = ["None"]
	for template in templates:
		enum_list.append(template)


	properties.append({
		"name":"Edit template" ,
		"type":TYPE_STRING ,
		"hint":PROPERTY_HINT_ENUM ,
		"hint_string" : ",".join(enum_list)
	})
	properties.append({
		"name":"Duplicate template" ,
		"type":TYPE_STRING ,
		"hint":PROPERTY_HINT_ENUM ,
		"hint_string" : ",".join(enum_list)
	})

	return properties

func _get(property: StringName) -> Variant:
	if property == "Edit template" or property == "Duplicate template":
		return "Templates..."
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property == "Edit template":
		_edit_template(value)
		return true
	if property == "Duplicate template":
		_duplicate_template(value)
		return true
	
	return false
