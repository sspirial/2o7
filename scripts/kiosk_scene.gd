extends Control

signal kiosk_scene_completed

@onready var dialogue_runner: DialogueRunner = $DialogueScene

func _ready() -> void:
	dialogue_runner.load_chapter("res://data/chapters/ch1_kiosk.json")
	dialogue_runner.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished(_chapter_id: String) -> void:
	kiosk_scene_completed.emit()
