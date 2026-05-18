@tool
extends Node
func trigger(id: int):
	var toast = EditorInterface.get_editor_toaster()
	toast.push_toast("[Model preview] Press ESC to interrupt the preview.", EditorToaster.SEVERITY_INFO)

	const MODEL_PREVIEW = preload("uid://c55sjnhrcmv01")
	EditorInterface.get_edited_scene_root().add_child(MODEL_PREVIEW.instantiate())
