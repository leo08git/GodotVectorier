@tool
extends PanelContainer
class_name _SettingsPopupValueHolder
@export var valueHolder: Node
@export var valueHolderProperty: StringName
@export var label: Node

var property: String

signal updateRequested

func setup(key: String, default: Variant):
	label.text = key.capitalize()
	valueHolder.set(valueHolderProperty, default)
	property = key

	if valueHolder is _SettingsPopupPathButton:
		valueHolder.tooltip_text = default

func get_value() -> Variant:
	return valueHolder.get(valueHolderProperty)

func get_property() -> String:
	return property

func requestUpdate() -> void:
	updateRequested.emit()
