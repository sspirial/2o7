extends Control

signal start_requested

@onready var new_game_btn: Button = $VBoxContainer/NewGameButton
@onready var continue_btn: Button = $VBoxContainer/ContinueButton
@onready var settings_btn: Button = $VBoxContainer/SettingsButton
@onready var shusha_btn: Button = $ShushaButton

func _ready() -> void:
	new_game_btn.pressed.connect(_on_new_game_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	shusha_btn.pressed.connect(func(): ShushaManager.open_shusha())
	
	continue_btn.visible = SaveManager.has_save()

func _on_new_game_pressed() -> void:
	GameState.reset_state()
	start_requested.emit()

func _on_continue_pressed() -> void:
	if SaveManager.load_game():
		start_requested.emit()
	else:
		_on_new_game_pressed()

func _on_settings_pressed() -> void:
	var settings_scene = load("res://scenes/menus/settings.tscn")
	if settings_scene:
		var inst = settings_scene.instantiate()
		add_child(inst)
