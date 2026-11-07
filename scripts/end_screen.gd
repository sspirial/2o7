extends Control

signal restart_requested

@onready var dialogue_runner: DialogueRunner = $DialogueScene
@onready var play_again_btn: Button = $PlayAgainBtn

func _ready() -> void:
	play_again_btn.pressed.connect(func(): restart_requested.emit())
	play_again_btn.visible = false
	
	dialogue_runner.load_chapter("res://data/chapters/end_screen.json")
	dialogue_runner.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished(_chapter_id: String) -> void:
	play_again_btn.visible = true
