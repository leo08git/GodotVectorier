extends UnityTools
class_name UnityGuidHandler

signal parse_finished
## { guid : file path }
var guid_paths: Dictionary[StringName, StringName] = {}

func parse_path(folder: String, force: bool = false) -> void:
	if is_parsed() and not force: 
		push_warning("[GuidHandler] Parse declined since we already parsed.")
		parse_finished.emit.call_deferred()
		return

	print("[GuidHandler] Looking for guids in folder %s." % folder)

	var paths: PackedStringArray = []
	Helper.seek_files(folder, paths, "meta")
	@warning_ignore("integer_division")

	print("[GuidHandler] Processing %d meta paths, this process is threaded and will be outputed when finished, do not close the application." % paths.size())
	WorkerThreadPool.add_task(_process_meta_paths.bind(paths), true)

func _process_meta_paths(paths: PackedStringArray) -> void:
	var guids = {}
	const image_formats: PackedStringArray = ["png", "jpg", "jpeg"]
	var textures_path: String = Helper.get_setting("textures_folder")

	var local_images: PackedStringArray = []
	Helper.seek_files(textures_path, local_images, "")
	var local_images_dictionary: Dictionary[String, String] = {}
	for img in local_images: local_images_dictionary[img.get_file()] = img
	print("- - - - - - - - - - - - - - - - - - - - ")
	print_rich("[GuidHandler][color=lightblue] Processing started")

	for meta_path in paths:
		var meta_target_path: String = meta_path.trim_suffix(".meta")

		if DirAccess.dir_exists_absolute(meta_target_path): continue # ignore folders
		if not FileAccess.file_exists(meta_target_path): continue

		if image_formats.has(meta_target_path.get_extension()): # Are we a image ?
			var meta_filename = meta_target_path.get_file()
			meta_target_path = local_images_dictionary.get(meta_filename, meta_target_path)

		var file = FileAccess.open(meta_path, FileAccess.READ)
		var current_line: String = ""
		while not current_line.begins_with("guid"):
			current_line = file.get_line()
		if current_line.is_empty():
			printerr("[GuidHandler] Meta from path \"%s\" does not have a guid parameter (what the hell?)" % meta_path)
		var yaml = YAML.parse(current_line)
		if yaml.has_error(): printerr("[GuidHandler] YAML error: \"%s\" while parsing guid from path \"%s\"" % [yaml.get_error(), meta_path])
		var guid_document = yaml.get_document(0)

		if guids.has(StringName(guid_document.guid)) and FileAccess.file_exists(guids[guid_document.guid]): continue
		guids[StringName(guid_document.guid)] = StringName(meta_target_path)

	print("[GuidHandler] Meta paths processed, merging.")
	print("- - - - - - - - - - - - - - - - - - - - ")
	_process_meta_paths_merge.call_deferred(guids)


func _process_meta_paths_merge(guids: Dictionary) -> void:
	guid_paths.merge(guids, true)
	print("[GuidHandler] Guid paths merged!")
	parse_finished.emit()

func get_guid_path(guid: StringName) -> String:
	if guid_paths.is_empty(): push_error("[GuidHandler] Trying to get guids on a empty guid handler."); return &""
	if not guid_paths.has(guid): push_error("[GuidHandler] Trying to get path from unexistant guid \"%s\"" % guid); return &""
	return guid_paths.get(guid, "")

func get_path_guid(path: String) -> StringName:
	if not guid_paths.values().has(path): push_error("[GuidHandler] Trying to get unexistant guid from path \"%s\"" % path); return &""
	for guid in guid_paths:
		if get_guid_path(guid) == path: return guid

	return &""

func set_guid_path(guid: StringName, path: StringName) -> void:
	guid_paths.set(guid, path)

func is_parsed() -> bool:
	return guid_paths.is_empty() == false
