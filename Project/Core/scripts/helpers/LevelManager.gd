class_name LevelManager

var xml: XMLNode
var LevelNode: LevelRoot

func _parse_class(object: ClassBase, data: Dictionary) -> void:
	if not (object is ClassObject) and not (object is ClassPrefab) and object.get_child_count() > 0:
		_parse_node_children(object, data)

	var RootObjects = data.get_or_add("RootObjects", [])
	var factors = data.get_or_add("factors", [])
	var models = data.get_or_add("models", [])

	RootObjects.append(object)

	if object is ClassFactor:
		var factor = _FactorToString(object.factor)
		if not factors.has(factor):
			factors.append(factor)

	elif object is ClassModel:
		models.append(object)

func _parse_non_class(object: Node, data: Dictionary) -> void:
	_parse_node_children(object, data)

func _parse_node_children(node: Node, data: Dictionary) -> void:
	for object in node.get_children():
		if object is ClassBase: _parse_class(object, data)
		else: _parse_non_class(object, data)

func _FactorToString(factor: float) -> String:
	return str(factor).trim_suffix(".0")

func Parse(level: LevelRoot) -> Dictionary:
	var data = {"root":level}
	_parse_node_children(level, data)

	var factors = data.get_or_add("factors", [])
	var models = data.get_or_add("models", [])
	var RootObjects = data.get_or_add("RootObjects", [])

	factors.sort()
	var root := XMLNode.new("Root")

	var structure: Dictionary = {
			"Sets" : XMLNode.new("Sets"),
			"Music" : XMLNode.new("Music", {"Name":level.music_name, "Volume": level.music_volume}, true),
			"ModelsCommon" : XMLNode.new("Models", {"Choice":"AITriggers", "Variant":"CommonMode"}),
			"ModelsHunter" : XMLNode.new("Models" , {"Choice":"AITriggers", "Variant":"HunterMode"}),
			"Coins" : XMLNode.new("Coins", {"Value":level.max_coins}, true),
			"Objects" : XMLNode.new("Objects", {"Name":"Money"}, true) ,
			"Track" : {} # { factor string : xmlnode }
			}

	for factor in factors:
		structure.Track.set(factor , [])

	for _set_ in level.sets: 
		structure.Sets.children.append(XMLNode.new("City", {"FileName":_set_}, true))

	for model in models: 
		match model.TargetMode:
			ClassBase.TargetModes.ALL:
				structure.ModelsCommon.children.append(model.get_xml_node())
				structure.ModelsHunter.children.append(model.get_xml_node())
			ClassBase.TargetModes.HunterMode:
				structure.ModelsHunter.children.append(model.get_xml_node())
			ClassBase.TargetModes.CommonMode:
				structure.ModelsCommon.children.append(model.get_xml_node())

	for object in RootObjects:
		if not object is ClassFactor: continue
		var node = Helper.ProcessClassXmlMode(object.get_xml_node(), object)
		if not node: printerr("Couldn't get XML from \"%s\"." % object.name); continue

		var object_factor = _FactorToString(object.factor)
		var factor_holder = structure.Track.get(object_factor)
		factor_holder.append(node)

	for structure_xml in structure.values(): 
		if structure_xml is XMLNode:
			root.children.append(structure_xml)

	var track_node := XMLNode.new("Track")
	root.append(track_node)
	for factor in structure.Track:
		var factor_xml := XMLNode.new("Object", {"Factor":factor})
		var content_xml := XMLNode.new("Content")
		track_node.append(factor_xml)
		factor_xml.append(content_xml)
		content_xml.children.append_array(structure.Track[factor])

	LevelNode = level
	xml = root

	return structure

func ToString() -> String:
	return xml.dump_str(1)

func ToClipboard() -> void:
	DisplayServer.clipboard_set(ToString())

## [method Parse] Needs to be called before this one.
func Compile() -> void:
	if Helper.is_vector_running():
		print_rich("[color=orange]Vector was running, closing it before compiling.")
		OS.execute("taskkill", ["/F", "/IM", "Vector.exe"])

	await OverrideLevel()
	await OverrideThumbnail()
	await OverrideTitle()

func OverrideLevel() -> void:
## info
	var LevelXml: String = xml.dump_str(1)

	var LevelXmlSeeker: DzSeeker = await DzSeeker.create("level_xml")
	if LevelXmlSeeker.state != OK: 
		printerr("Error while seeking level_xml.dz.")
		return
	var map_file_name = LevelNode.override_this_level + ".xml"
	var map_file_path = LevelXmlSeeker.get_file(map_file_name)
	print_rich("[i][color=lightblue]Informations:\n	level dz path: %s\n	map file path: %s" % [
		LevelXmlSeeker.dz_path ,
		map_file_path])

## save xml to file
	print_rich("[color=lightyellow]Opening file path %s." % map_file_path)
	var f = FileAccess.open(map_file_path , FileAccess.WRITE)
	if FileAccess.get_open_error() != OK: printerr("Unable to open path %s, error %d." % [map_file_path, FileAccess.get_open_error()]); return

	print_rich("[color=lightyellow]Storing XML...")
	var store_result = f.store_string(LevelXml)
	if not store_result: # results false if we couldnt store it for some reason.
		printerr("Unable to store xml on file %s. Error: %s" % [map_file_path, str(f.get_error())])
		f.close()
		return
	f.close()

## compile dz file
	print_rich("[color=green]Opened and stored content in the XML file, now compiling. [color=yellow](May take a while on the first time.)")
	if not await (LevelXmlSeeker.compile()): printerr("Couldn't compile the dz."); return
	print_rich("[color=green]Compiled")


	print_rich("\n[color=orange]Successfully compiled the level :D")

	var b = Helper.get_setting("open_vector_after_compile")
	if (b is bool and b == true):
		OS.shell_open("steam://rungameid/248970")

func OverrideTitle() -> void:
	if LevelNode.level_name.is_empty(): return
	if LevelNode.level_name == LevelNode._processed_level_name: return

	print_rich("\n[color=yellow]Processing title... Opening common_xml.dz")
	var title_seeker: DzSeeker = await DzSeeker.create("common_xml")
	if title_seeker.state != OK: printerr("Couldn't create a DZseeker for title processing."); return
	var localization_path: String = title_seeker.get_file("localization_all.xml")
	var xml_key: String = "item_%s" % LevelNode.override_this_level
	print_rich("[color=green]Opened, initializing XMLNode and altering language keys...")

	var xml_root: XMLNode = XML.parse_file(localization_path).root
	var xml_title_holder: XMLNode = xml_root.find_child(xml_key)
	for lang_key in Helper.LocalizationAttributeKeys:
		xml_title_holder.attributes.set(lang_key, LevelNode.level_name)

	print_rich("[color=yellow]Saving")
	FileAccess.open(localization_path, FileAccess.WRITE).store_string(xml_root.dump_str(1))

	print_rich("[color=green]Saved! [color=yellow]Now compiling...")
	if not await title_seeker.compile(): printerr("Couldn't compile title."); return
	print_rich("[color=green]Compiled title. [common_xml]")
	LevelNode._processed_level_name = LevelNode.level_name

func OverrideThumbnail() -> void:
	if LevelNode.level_thumbnail_path.is_empty(): return 
	if LevelNode.level_thumbnail_path == LevelNode._processed_thumbnail_path: return
	if not FileAccess.file_exists(LevelNode.level_thumbnail_path):
		push_error("[LevelManager] Level thumbnail path is invalid."); return
	var thumbnail_filename: String = "%s.png" % LevelNode.override_this_level

	print_rich("\n[color=yellow]Processing thumbnail change... Opening GUI_2048_1536.dz")
	var thumbnail_seeker: DzSeeker = await DzSeeker.create("GUI_2048_1536")
	if thumbnail_seeker.state != OK: printerr("Couldn't create a DZseeker for thumbnail processing."); return
	var override_path: String = thumbnail_seeker.get_file(thumbnail_filename)
	print_rich("[color=green]Opened, overriding image")
	if DirAccess.copy_absolute(LevelNode.level_thumbnail_path, override_path) != OK: 
		printerr("Unable to copy from \"%s\" to \"%s\", Cancelling operation." % [LevelNode.level_thumbnail_path, override_path]); return
	print_rich("[color=yellow]Now compiling...")
	if not await thumbnail_seeker.compile(): printerr("Couldn't compile thumbnail."); return
	print_rich("[color=green]Compiled thumbnail. [GUI_2048_1536]")
	LevelNode._processed_thumbnail_path = LevelNode.level_thumbnail_path

static func CreateFromLevel(level: LevelRoot) -> LevelManager:
	var m = LevelManager.new()
	await m.Parse(level)
	return m
