@tool
extends Button
class_name _SettingsPopupPathButton

signal pathChosen
@export var mode: DisplayServer.FileDialogMode = DisplayServer.FileDialogMode.FILE_DIALOG_MODE_OPEN_DIR

func _pressed() -> void:
	DisplayServer.file_dialog_show(
		"Choose a path", 
		ProjectSettings.globalize_path("res://" if get_meta("path").is_empty() else get_meta("path")), 
		"", 
		true, 
		mode, 
		[], 
		_fileChosen)

func _fileChosen(status: bool, selected_paths: PackedStringArray, _i) -> void:
	if status:
		set_meta("path", selected_paths.get(0))
		tooltip_text = selected_paths.get(0)
		pathChosen.emit()
