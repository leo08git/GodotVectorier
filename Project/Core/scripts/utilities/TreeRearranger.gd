@tool
extends Utilities
## When triggered, rearranges a tree using [method String.match].
class_name TreeRearrange

## Whose children we'll be rearranging
@export var tree: Node
## Where sort parents will go, if empty, uses [member tree] instead.
@export var sort_destination: Node
## If on, gets not only direct children but the entirety of the tree.
@export var recursive_picking: bool = false

@export_group("Sorting")
## Sorting structure, usage: [code]Match parameter : Sort parent name[/code] [br]
## E.g: [br][b] "Trigger*":"TriggerNodes" [br]
## When sorting, it'll create a node named "TriggerNodes", [br]
## then reparent all node names that begins with [code]Trigger[/code] to [code]TriggerNodes
@export var sort_definitions: Dictionary[StringName, StringName] = {}
@export var max_operations_per_frame: int = 3:
	set(value):
		if value <= 0: value = 1
		max_operations_per_frame = value
@export_tool_button("Sort") var tb_sort = sort

func sort() -> void:
	if not is_instance_valid(tree): printerr("No tree was specified."); return
	if is_zero_approx(tree.get_child_count()): printerr("The tree is empty."); return
	if not is_instance_valid(sort_destination): 
		sort_destination = tree
		push_warning("No sort destination was specified, using tree instead.")

	var sort_targets: Array[Node] = Helper.get_all_children(tree) if recursive_picking else tree.get_children()
	var index = 0

	var definition_filters := PackedStringArray(sort_definitions.keys())
	var definition_nodes: Dictionary[StringName, Node] = {}

	for filter_node_name in definition_filters:
		var filter_name = sort_definitions[filter_node_name]
		var filter_node: Node = null

		if sort_destination.has_node(NodePath(filter_name)):
			filter_node = tree.get_node(NodePath(filter_name))
		else:
			filter_node = Node.new()
			filter_node.name = filter_name
			Helper.add_node(filter_node, sort_destination)
		if not is_instance_valid(filter_node): continue

		definition_nodes.set(filter_node_name, filter_node)

	for target in sort_targets:
		if target == self: continue
		if target.is_ancestor_of(self): continue
		if not target.is_part_of_edited_scene(): 
			push_warning("Skipping target %s"); continue

		var target_parent: Node = null

		for filter_parameter in definition_filters:
			if not target.name.match(filter_parameter): continue
			target_parent = definition_nodes[filter_parameter]

		var _tname = target.name
		if target_parent: target.reparent(target_parent)
		target.name = _tname

		index += 1
		if index > max_operations_per_frame:
			index = 0
			await get_tree().process_frame
