@tool
extends Node
func trigger(id: int):
	var toast = EditorInterface.get_editor_toaster()
	var selection: Array[Node] = EditorInterface.get_selection().get_selected_nodes()

	if selection.is_empty():
		toast.push_toast("[Mass base script apply] Selection is empty.", EditorToaster.SEVERITY_WARNING)

	var nodes: Array[Node] = selection

	if id == 1:
		nodes = []
		for selected in selection:
			nodes.append_array(Helper.get_all_children(selected))

	for node in nodes:
		if node.get_script() != null and id == 0:
			toast.push_toast("[Mass base script apply] node %s already has a script. Use brute mode to force script application." % node.name, EditorToaster.SEVERITY_ERROR)
			continue

		node.set_script(preload("uid://bqceui7yj7wyd"))

		if node is Sprite2D:
			node.centered = false
