extends Object
## Helper to quickly handle dz operations. Usage: [code]var seeker = await DzSeeker.create("level_xml")
class_name DzSeeker
var dz_path: String = ""
var decompiled_directory: String = ""
var state: Error = OK

## Creates a dzseeker, decompiles the dz and returns the dzseeker. Usage: DzSeeker.create("level_xml")
static func create(dz_name: String, backup: bool = true) -> DzSeeker:
	var instance := DzSeeker.new()
	dz_name += ".dz"
	if Helper.get_setting("game_folder").is_empty(): 
		printerr("[DzSeeker] The game path folder is not set. Cancelling operation")
		instance.state = ERR_BUG
		return
	elif not DirAccess.dir_exists_absolute(Helper.get_setting("game_folder")): 
		printerr("[DzSeeker] The game path folder is invalid! Cancelling operation")
		instance.state = ERR_BUG
		return

	instance.dz_path = Helper.get_setting("game_folder").path_join(dz_name)
	instance.decompiled_directory = instance.dz_path.get_basename()
	var pre_decompiled: bool = DirAccess.dir_exists_absolute(instance.decompiled_directory)

	if pre_decompiled:
		pass
	else:
		if backup:
			var copy_path: String = instance.dz_path.get_basename() + "_backup.dz"
			DirAccess.copy_absolute(instance.dz_path, copy_path)
		if EditorDzHandler.dzip_decompile(instance.dz_path) != OK: return
		await EditorDzHandler.decompile_process_terminated

	return instance

## Returns the absolute path for a file present in the dz.
func get_file(filename: String) -> String:
	return decompiled_directory.path_join(filename)

func compile() -> bool:
	if EditorDzHandler.dzip_compile(decompiled_directory) != OK: return false
	await EditorDzHandler.compile_process_terminated
	return true
