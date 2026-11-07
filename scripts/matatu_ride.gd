extends Control

signal matatu_ride_completed

@onready var dialogue_runner: DialogueRunner = $DialogueScene
@onready var bg: Control = $BgMatatuInterior

func _ready() -> void:
	_start_bounce_effect()
	dialogue_runner.load_chapter("res://data/chapters/ch1_matatu_ride.json")
	dialogue_runner.dialogue_finished.connect(_on_dialogue_finished)

func _start_bounce_effect() -> void:
	if bg:
		var tween := create_tween().set_loops()
		tween.tween_property(bg, "position:y", -6.0, 0.4).set_trans(Tween.TRANS_SINE)
		tween.tween_property(bg, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_SINE)

func _on_dialogue_finished(_chapter_id: String) -> void:
	matatu_ride_completed.emit()
