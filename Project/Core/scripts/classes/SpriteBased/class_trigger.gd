@tool
extends ClassFactor
class_name ClassTrigger
const TRIGGER_TEMPLATES = preload("uid://bp7w84ksmuoxw")

## ZapXML is a interface to make triggers.
@export_tool_button("Command helper called ZapXML (Github link)" , "TextureRect") var open_xzap = func(): OS.shell_open("https://github.com/leo08git/ZapXML")
@export_multiline var Command = ""

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	var enum_list = TRIGGER_TEMPLATES.templates.keys()

	properties.append({
		"name":"Load trigger preset" ,
		"type":TYPE_STRING ,
		"hint":PROPERTY_HINT_ENUM ,
		"hint_string" : ",".join(enum_list)
	})

	return properties

func _get(property: StringName) -> Variant:
	if property == "Load trigger preset":
		return "Presets..."
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property == "Load trigger preset":
		_load_preset(value)
		return true
	return false

func _load_preset(preset: String) -> void:
	if TRIGGER_TEMPLATES.templates.has(preset):
		print("Preset %s loaded." % preset)
		Command = TRIGGER_TEMPLATES.templates[preset]

func get_xml_node() -> XMLNode:
	var pos = Helper.get_class_position(self)
	var size = get("transform").get_scale() * get("texture").get_size()
	var req_attrs = {
			"X":pos.x, 
			"Y":pos.y, 
			"Width":size.x, 
			"Height":size.y ,
			"Name":name}
	req_attrs.merge(attributes, true)

	var node = XMLNode.new("Trigger", req_attrs)
	var xml_sub = XMLNode.new("Content")
	xml_sub.content = Command
	node.children.append(xml_sub)

	return node
