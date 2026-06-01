@tool
extends Node
const DZIP_PATH = "res://Core/dependency/dzip.exe"
const OutputHeader = "[DzHandler] "
var GlobalDzPath = ProjectSettings.globalize_path(DZIP_PATH.get_base_dir())

signal decompile_process_terminated
signal compile_process_terminated

func dzip_decompile(path_to_file: String , warn := true) -> Error:
	if not FileAccess.file_exists(path_to_file): 
		decompile_process_terminated.emit()
		push_error(OutputHeader, "Tried decompiling unexistant path \"%s\"" % path_to_file , true)
		return ERR_DOES_NOT_EXIST

## Run CMD, then cd to the file path folder, then run dzip to decompile the folder
	var args = ["/C" , "cd \"%s\"&&dzip -d \"%s\"" % [GlobalDzPath , path_to_file]]
	var result = OS.execute_with_pipe("cmd.exe" , args , false)

	if result.is_empty(): push_error(OutputHeader, "Could not create dzip process to decompile \"%s\"." % path_to_file , true); return FAILED
	var stderr: FileAccess = result["stderr"]

## Create a thread to watch the CMD process to check when it's completed
	var decompile_thread = Thread.new()
	var threadcheck = decompile_thread.start(watch_thread.bind(result["pid"] , 
		func(): 
			decompile_thread.wait_to_finish()
			if warn: print(OutputHeader, "The dz file has been decompiled.")
			decompile_process_terminated.emit.call_deferred() ,
		func(exit_code: int): 
			decompile_thread.wait_to_finish()
			push_error(OutputHeader, "An error occured while decompiling \"%s\". exit code: %s" % [path_to_file, exit_code])
			print(" - - - - - - - - - - - - Debug since the process failed.")
			print(OutputHeader, "Arguments: ", args)
			print(OutputHeader, "The following lines that start with \"DzipReport: \" are 25 lines from the dzip cmd process itself. Empty lines will be ignored.")
			for i in 25:
				var line = stderr.get_line()
				if !line.is_empty():
					print("DzipReport line %d: " % i, line)
			print(" - - - - - - - - - - - - Debug since the process failed.")
			decompile_process_terminated.emit.call_deferred()
))
	if threadcheck != OK: return FAILED
	return OK

func dzip_compile(path_to_folder: String , warn := true) -> Error:
	if not DirAccess.dir_exists_absolute(path_to_folder): 
		compile_process_terminated.emit.call_deferred()
		push_error(OutputHeader, "Path doesn't exist." , true)
		return ERR_DOES_NOT_EXIST

## Setup config for dzip
	var dcl_path = path_to_folder.get_base_dir() + "/dc.dcl"
	var configdcl = FileAccess.open(dcl_path , FileAccess.WRITE)
	var config: String = 'archive "%s"\nbasedir "%s"' % [path_to_folder.get_basename() + ".dz" , path_to_folder]

## Setup all the files on config dcl and close it
	for file in Helper.get_all_files_relative(path_to_folder):
		config += '\nfile "%s" 0 zlib' % file

	configdcl.store_string(config)
	configdcl.close()

## Run dzip on configdcl
	var args = ["/C" , 'cd \"%s\"&&dzip \"%s\"' % [GlobalDzPath , dcl_path]]
	var result = OS.execute_with_pipe("cmd.exe" , args , true)

	if result.is_empty(): push_error(OutputHeader, "Wasn't able to run windows CMD to create DZIP process."); return FAILED
	var stderr: FileAccess = result["stderr"]

## Watch the cmd (read the decompile one for more details)
	var compile_thread = Thread.new()
	var threadcheck = compile_thread.start(watch_thread.bind(result["pid"] , 
		func(): # success
			var DclRemoveResult = DirAccess.remove_absolute(dcl_path)
			if DclRemoveResult != OK: push_error(OutputHeader, "Unable to delete temporary dc.dcl. Error \"%s\". (dzip config file)" % DclRemoveResult)
			compile_thread.wait_to_finish()
			if warn: 
				print(OutputHeader, "The dz file has been compiled.") 
			compile_process_terminated.emit.call_deferred()
, 
		func(exit_code: int): # failed
			var DclRemoveResult = DirAccess.remove_absolute(dcl_path)
			if DclRemoveResult != OK: push_error(OutputHeader, "Unable to delete temporary dc.dcl. (dzip config file)")
			compile_thread.wait_to_finish()
			push_error(OutputHeader, "An unknown error occured while compiling \"%s\". exit code: %s (Thread called fail)" % [path_to_folder , exit_code])
			print(" - - - - - - - - - - - - Debug since the process failed.")
			print(OutputHeader, "Arguments: ", args)
			print(OutputHeader, "The following lines that start with \"DzipReport: \" are 25 lines from the dzip cmd process itself. Empty lines will be ignored.")
			for i in 25:
				var line = stderr.get_line()
				if !line.is_empty():
					print("DzipReport line %d: " % i, line)
			print(" - - - - - - - - - - - - Debug since the process failed.")
			compile_process_terminated.emit.call_deferred()
))

# debug
	#var s = (result["stdio"] as FileAccess)
	#for i in range(10):
		#print("stdio: " , s.get_line())


	if threadcheck != OK: return FAILED

	return OK

func watch_thread(pid: int , callback: Callable , error_fallback: Callable) -> void:
	while OS.is_process_running(pid):
		OS.delay_msec(50)
	var exit_code = OS.get_process_exit_code(pid)
	if exit_code != 0: 
		error_fallback.call_deferred(exit_code) 
		return
	callback.call_deferred()

func dzip_execute() -> void:
	var dzip_action = EditorAutoload.level.dzip_action

	if EditorAutoload.level.dzip_input.is_empty():
		push_error("Dzip input is empty!")
		return

	var dzip_process_name: String = LevelRoot.DzipToolActions.keys()[dzip_action]
	var method_name: String = "dzip_%s" % dzip_process_name
	var dzsignal_name: String = "%s_process_terminated"  % dzip_process_name
	var dzsignal_object = Signal(EditorDzHandler , dzsignal_name)

	print("Working on it... running method \"%s\" on dz handler." % method_name)
	EditorDzHandler.call(method_name , EditorAutoload.level.dzip_input)
	print("awaiting signal for %s..." % dzsignal_name.capitalize())
	await dzsignal_object
	print("Await done. Opening folder.")
	OS.shell_open(EditorAutoload.level.dzip_input.get_basename())
