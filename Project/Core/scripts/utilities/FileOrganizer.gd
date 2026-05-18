@tool
extends Utilities
## When triggered, rearranges a dir using [method String.match].
class_name FileOrganizer

## Which folder we will organize
@export_global_dir var dir: String

## Sorting structure, usage: [code]Match parameter : Sort parent name[/code] [br]
## E.g: [br][b] "Trigger*":"TriggerDir" [br]
## When sorting, it'll create a folder named "TriggerDir", [br]
## then move all file names that begins with [code]Trigger[/code] to [code]TriggerDir
@export var sort_definitions: Dictionary[StringName, StringName] = {}
@export var max_operations_per_frame: int = 3:
	set(value):
		if value <= 0: value = 1
		max_operations_per_frame = value
@export_tool_button("Organize") var tb_sort = sort

func sort() -> void:

	var sort_targets: PackedStringArray = DirAccess.get_files_at(dir)
	var index = 0

	var definition_filters := PackedStringArray(sort_definitions.keys())
	var definition_directories: Dictionary[StringName, String] = {}

	for filter_node_name in definition_filters:
		var directory_name := sort_definitions[filter_node_name]
		var directory_path := dir.path_join(directory_name)

		if not DirAccess.dir_exists_absolute(directory_path):
			DirAccess.make_dir_absolute(directory_path)

		definition_directories.set(directory_name, directory_path)

	for target in sort_targets:

		for filter_parameter in definition_filters:
			if not target.match(filter_parameter): continue
			var target_path: String = dir.path_join(target)
			var target_new_path: String = (dir.path_join(sort_definitions[filter_parameter])).path_join(target)
			if not FileAccess.file_exists(target_path): continue
			DirAccess.copy_absolute(target_path, target_new_path)
			DirAccess.remove_absolute(target_path)

		index += 1
		if index > max_operations_per_frame:
			index = 0
			await get_tree().process_frame
