@tool
extends PanelContainer

func read(jsonData: Dictionary) -> void:
	var nameIdx: int = 0
	for key in jsonData:
		var value = jsonData.get(key)

		var n: Node

		if "folder" in key:
			n = load("uid://cd3law3ptf2if").instantiate()
		elif "file" in key:
			n = load("uid://cjbjof27oilkk").instantiate()
		elif value is bool:
			n = load("uid://cmm0aw5sihtwq").instantiate()
		elif value is String:
			n = load("uid://cds4m2wg0xn10").instantiate()

		$list.add_child(n)

		n.name = str(nameIdx)
		if n is _SettingsPopupValueHolder:
			n.setup(key, value)
			n.updateRequested.connect.call_deferred(save)

		nameIdx += 1

func save() -> void:
	print("[Editor] Saving settings...")
	var dic: Dictionary = {}

	for child in $list.get_children():
		if child is _SettingsPopupValueHolder:
			dic.set(
				child.get_property(), child.get_value()
			)

	var r = FileAccess.open("res://settings.json", FileAccess.WRITE)
	r.store_string(
		JSON.stringify(dic, "", false)
	)
	print("[Editor] Saved settings.")

func _ready() -> void:
	read.call_deferred(
		JSON.parse_string(
			FileAccess.get_file_as_string("settings.json")
		)
	)
