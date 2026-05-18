@tool
extends Node

signal decompile_process_terminated
signal compile_process_terminated

## Used to rebuild dzip from scratch when compiling or decompiling
var current_path: String
var is_process_running := false

#var decompile_thread: Thread
#var compile_thread: Thread

## Redirected version of OS.alert so the main window dont get on front of the alert ones
func dzprint(text: String, error: bool):
	if error:
		push_error("[DzHandler] %s" % text)
	else:
		print("[DzHandler] %s" % text)

func remove_dzip() -> void:
	var result = DirAccess.remove_absolute(current_path + "/dzip.exe")
	if result != OK: dzprint("Unable to delete temporary dzip.exe." , true)

func remove_dcl() -> void:
	var result = DirAccess.remove_absolute(current_path + "/dc.dcl")
	if result != OK: dzprint("Unable to delete temporary dc.dcl. (dzip config file)" , true)

const DZIP_PATH = "res://Core/dependency/dzip.exe"
func dzip_decompile(path_to_file: String , warn := true) -> Error:
	if not FileAccess.file_exists(path_to_file): 
		decompile_process_terminated.emit()
		dzprint("Path doesnt exist." , true)
		return ERR_DOES_NOT_EXIST

	current_path = path_to_file.get_base_dir()
	var path_to_dzip = path_to_file.get_base_dir() + "/dzip.exe"
## Create a new dzip.exe on the file's folder
	var dzip = FileAccess.open(path_to_dzip , FileAccess.WRITE)
	if not dzip: dzprint("An error occured when creating a dzip file on the destination path, error: %s (show this to the developer)" % FileAccess.get_open_error() , true); return Error.ERR_BUG

## Copy original bytes to the new dzip
	dzip.store_buffer(FileAccess.get_file_as_bytes(DZIP_PATH))
	dzip.close()

## Run CMD, then cd to the file path folder, then run dzip to decompile the folder
	var result = OS.execute_with_pipe("cmd.exe" , ["/C" , "cd %s&&dzip -d %s" % [path_to_file.get_base_dir() , path_to_file.get_file()]] , false)

	is_process_running = true
	if result.is_empty(): dzprint("Something went wrong while decompiling %s" % path_to_file.get_file() , true); is_process_running = false; return FAILED

## Create a thread to watch the CMD process to check when it's completed
	var decompile_thread = Thread.new()
	var threadcheck = decompile_thread.start(watch_thread.bind(result["pid"] , 
		func(): 
			decompile_process_terminated.emit()
			remove_dzip()
			decompile_thread.wait_to_finish()
			if warn: dzprint("The dz file has been decompiled." , false) , 
		func(): 
			decompile_process_terminated.emit()
			remove_dzip()
			decompile_thread.wait_to_finish()
			dzprint("An error occured while decompiling" , true)
))
	if threadcheck != OK: return FAILED
	return OK

func dzip_compile(path_to_folder: String , warn := true) -> Error:
	if not DirAccess.dir_exists_absolute(path_to_folder): 
		compile_process_terminated.emit()
		dzprint("Path doesn't exist." , true)
		return ERR_DOES_NOT_EXIST

	current_path = path_to_folder.get_base_dir()
	var path_to_dzip = path_to_folder.get_base_dir() + "/dzip.exe"
## Create a new dzip.exe on the file's folder
	var dzip = FileAccess.open(path_to_dzip , FileAccess.WRITE)
## Copy original bytes to the new dzip
	dzip.store_buffer(FileAccess.get_file_as_bytes(DZIP_PATH))
	dzip.close()

## Setup config  for dzip
	var configdcl = FileAccess.open(path_to_folder.get_base_dir() + "/dc.dcl" , FileAccess.WRITE)
	var config: String = 'archive "%s"\nbasedir "%s"' % [path_to_folder.get_basename() + ".dz" , path_to_folder]

## Setup all the files on config dcl and close it
	for file in Helper.get_all_files_relative(path_to_folder):
		config += '\nfile "%s" 0 zlib' % file

	configdcl.store_string(config)
	configdcl.close()

## Run dzip on configdcl
	var args = ["/C" , 'cd %s&&dzip dc.dcl' % path_to_folder.get_base_dir()]
	var result = OS.execute_with_pipe("cmd.exe" , args , true)

	is_process_running = true
	if result.is_empty(): dzprint("Something went wrong while running CMD" , true); return FAILED

## Watch the cmd (read the decompile one for more details)
	var compile_thread = Thread.new()
	var threadcheck = compile_thread.start(watch_thread.bind(result["pid"] , 
		func(): # success
			remove_dzip()
			remove_dcl()
			compile_thread.wait_to_finish()
			if warn: 
				dzprint("The dz file has been compiled." , false) 
			compile_process_terminated.emit()
, 
		func(): # failed
			remove_dzip()
			remove_dcl()
			compile_thread.wait_to_finish()
			dzprint("An error occured while compiling" , true)
			compile_process_terminated.emit()
))

# debug
	#var s = (result["stdio"] as FileAccess)
	#for i in range(10):
		#print("stdio: " , s.get_line())


	if threadcheck != OK: return FAILED

	return OK

func watch_thread(pid: int , callback: Callable , error_fallback: Callable) -> void:
	while OS.is_process_running(pid):
		OS.delay_msec(5)

## These only run after the "while" loop is false, which is when CMD stops running
## Checks if cmd failed somehow (if it fails, take the L, because i won't know how to fix!)
	if OS.get_process_exit_code(pid) != 0: 
		error_fallback.call_deferred(); set_deferred("is_process_running" , false); return
## Function to run outside of the thread cuz it crahses if we dont
	callback.call_deferred(); set_deferred("is_process_running" , false)

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
