@tool
extends Node

func randomize_dz() -> void:
	if EditorAutoload.level.randomize_dz_path.is_empty(): EditorInterface.get_editor_toaster().push_toast("No dz path set.", EditorToaster.SEVERITY_WARNING); return

	var filelist: Array = DirAccess.get_files_at(EditorAutoload.level.randomize_dz_path)
	var randomized_files: Array = []

	for file in filelist:
		if file.get_extension() in EditorAutoload.level.randomize_files_exclude_extensions: continue
		if randomized_files.has(file): continue

		var fullpath = EditorAutoload.level.randomize_dz_path.path_join(file)
		var fullpath_2 = filelist.pick_random()
		DirAccess.rename_absolute(fullpath_2, fullpath_2 + "_TEMP")
		DirAccess.rename_absolute(fullpath, fullpath_2)
		DirAccess.rename_absolute(fullpath_2 + "_TEMP", fullpath)
		randomized_files.append(file)
		randomized_files.append(fullpath_2.get_file())
