extends Control

signal accepted

@onready var continue_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/ContinueButton

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue_pressed)

func _on_continue_pressed() -> void:
	accepted.emit()
