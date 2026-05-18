@tool
extends ClassBase
class_name ClassFactor

const PRESETS = {
	"Main" : 1.0 ,
	"Backdrop" : 0.5 , 
	"Overlay" : 1.0000001 ,
	"Background" : 0.05}

@export var factor: float = 1.0

@export_enum("Main" , "Backdrop" , "Overlay" , "Background") var presets: String = "Main":
	set(value):
		if PRESETS.has(value):
			factor = PRESETS[value]
	get():
		return "Select..."
