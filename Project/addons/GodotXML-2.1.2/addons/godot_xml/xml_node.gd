## Represents an XML element (AKA XML node). Hint: if there's only one child with
## the same name, you can access it via [code]this_node.my_child_name[/code]!
class_name XMLNode extends RefCounted

## XML node name.
var name: String = ""

## XML node attributes.
var attributes: Dictionary = {}

## XML node content.
var content: String = ""

## XML node CDATA.
var cdata: Array[String] = []

## Whether the XML node is an empty node (AKA standalone node).
var standalone: bool = false

## XML node's children.
var children: Array[XMLNode] = []

var _node_props: Array
var _node_props_initialized: bool = false
const KNOWN_PROPERTIES: Array[String] = ["name", "attributes", "content", "cdata", "standalone", "children"]

## Converts this node (and all of it's children) into a [Dictionary].
## Name is set as [code]__name__: name[/code].
## Content is set as [code]__content__: content[/code].
## CDATA is set as [code]__cdata__: [cdata, ...][/code].
## Attributes are set as [code]attrs: {attr_name: attr_value}[/code].
## Children are set as [code]children: {child_name: child_dict}[/code].
func to_dict() -> Dictionary:
	var output := {}

	output["__name__"] = self.name
	output["__content__"] = self.content
	output["__cdata__"] = self.cdata
	output["attrs"] = self.attributes

	var children_dict := {}

	for child in self.children:
		children_dict[child.name] = child.to_dict()

	output["children"] = children_dict

	return output

## Dumps this node to the specified file.
## The file at the specified [code]path[/code] [b]must[/b] be writeable.
## See [method XMLNode.dump_str] for further documentation.
func dump_file(
	path: String,
	pretty: bool = false,
	indent_level: int = 0,
	indent_length: int = 2,
) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	var xml: String = self.dump_str(pretty, indent_level, indent_length)
	file.store_string(xml)
	file = null


## Dumps this node to a [PackedByteArray].
## See [method XMLNode.dump_str] for further documentation.
func dump_buffer(
	pretty: bool = false,
	indent_level: int = 0,
	indent_length: int = 2,
) -> PackedByteArray:
	return self.dump_str(pretty, indent_level, indent_length).to_utf8_buffer()


## Dumps this node to a [String].
## Set [param pretty] to [code]true[/code] if you want indented output.
## If [param pretty] is [code]true[/code], [param indent_level] controls the initial indentation level.
## If [param pretty] is [code]true[/code], [param indent_length] controls the length of a single indentation level.
func dump_str(
	pretty: bool = false,
	indent_level: int = 0,
	indent_length: int = 2,
	include_self: bool = true,
) -> String:
	if indent_level < 0:
		push_warning("indent_level must be >= 0")
		indent_level = 0

	if indent_length < 0:
		push_warning("indent_length must be >= 0")
		indent_length = 0

	return self._dump(include_self) if not pretty else self._dump_pretty(indent_level, indent_length, include_self)

func _to_string():
	return "<XMLNode name=%s attributes=%s content=%s cdata=%s standalone=%s children=%s>" % [
		name ,
		attributes ,
		content ,
		cdata ,
		standalone ,
		children
	]


# Dotted access via GDScript
func _get(property: StringName):
	if not self._node_props_initialized:
		self._initialize_node_properties()

	if (
		property not in KNOWN_PROPERTIES
		and property in self._node_props
	):
		for child in self.children:
			if child.name == property:
				return child


# Dotted access via editor
func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []

	if not self._node_props_initialized:
		self._initialize_node_properties()

	for child_name in self._node_props:
		props.append({
			"name": child_name,
			"type": TYPE_OBJECT,
			"class_name": "XMLNode",
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "",
		})

	return props


func _initialize_node_properties() -> void:
	var names_to_nodes := {}

	for child: XMLNode in self.children:
		if not child.name in names_to_nodes.keys():
			names_to_nodes[child.name] = child
		else:
			names_to_nodes.erase(child.name)

	self._node_props = names_to_nodes.keys()
	self._node_props_initialized = true


func _dump(include_self: bool) -> String:
	var attribute_string := ""
	var children_string := ""
	var cdata_string = ""

	if not self.attributes.is_empty():
		attribute_string += " "

		for attribute_key in self.attributes:
			var attribute_value := self.attributes.get(attribute_key)

			if attribute_value is String:
				attribute_value = attribute_value.xml_escape(true)

			attribute_string += '{key}="{value}"'.format({"key": attribute_key, "value": attribute_value})

	for child: XMLNode in self.children:
		children_string += child._dump(true)

	for cdata_content in self.cdata:
		cdata_string += "<![CDATA[%s]]>" % cdata_content.replace("]]>", "]]]]><![CDATA[>")

	if self.standalone:
		return "<" + self.name + attribute_string + "/>"
	else:
		return (
			"<" + self.name + attribute_string + ">" +
			self.content + cdata_string + children_string +
			"</" + self.name + ">"
		) if include_self else children_string


func _dump_pretty(indent_level: int, indent_length: int, include_self: bool) -> String:
	var indent_string := " ".repeat(indent_level * indent_length)
	var indent_next_string := indent_string + " ".repeat(indent_length)
	var attribute_string := ""
	var content_string := "\n" + indent_next_string + self.content if not self.content.is_empty() else ""
	var children_string := ""
	var cdata_string := ""

	if not self.attributes.is_empty():
		for attribute_key in self.attributes:
			var attribute_value := self.attributes.get(attribute_key)

			if attribute_value is String:
				attribute_value = attribute_value.xml_escape(true)

			attribute_string += ' {key}="{value}"'.format({"key": attribute_key, "value": attribute_value})

	for child: XMLNode in self.children:
		children_string += "\n" + child.dump_str(true, indent_level + 1, indent_length)

	for cdata_content in self.cdata:
		cdata_string += "\n" + indent_next_string + (
			"<![CDATA[%s]]>" % cdata_content.replace("]]>", "]]]]>\n%s<![CDATA[>" % indent_next_string)
		)

	if self.standalone:
		return indent_string + "<" + self.name + attribute_string + "/>"
	else:
		return (
			indent_string + "<" + self.name + attribute_string + ">" +
			content_string + cdata_string + children_string +
			"\n" + indent_string + "</" + self.name + ">"
		) if include_self else children_string.strip_edges(1,0)

func _init(init_name: String = "", init_attributes: Dictionary = {} , init_self_enclose: bool = false) -> void:
	name = init_name
	attributes = init_attributes
	standalone = init_self_enclose

func get_all_children() -> Array[XMLNode]:
	var a = [] as Array[XMLNode]

	for c: XMLNode in children:
		a.append(c)
		a.append_array(c.get_all_children())

	return a

func find_child(Name: String) -> XMLNode:
	for c in get_all_children():
		if c.name == Name:
			return c
	return null

func has_child(Name: String) -> bool:
	for c in children:
		if c.name == Name:
			return true
	return false

## E.g: [code]XMLNode.from_tree("level/content")[/code] = 2 XMLNodes, content being a child of level. Returns the first child
static func from_tree(tree: String) -> XMLNode:
	var xmls: Array[XMLNode] = []
	for slice in tree.split("/"):
		var newxml = XMLNode.new(slice)
		if xmls.size() > 0: 
			xmls[xmls.size() - 1].children.append(newxml)
		xmls.append(newxml)

	return xmls[0]

## Alias to children.append
func append(child: XMLNode) -> void:
	children.append(child)
