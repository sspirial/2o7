extends Control

signal resume_requested
signal skip_requested(summary: String)

@onready var resume_btn: Button = $PanelContainer/MarginContainer/VBox/ResumeButton
@onready var skip_btn: Button = $PanelContainer/MarginContainer/VBox/SkipButton
@onready var settings_btn: Button = $PanelContainer/MarginContainer/VBox/SettingsButton
@onready var help_btn: Button = $PanelContainer/MarginContainer/VBox/HelpButton
@onready var help_panel: PanelContainer = $HelpPanel
@onready var help_close_btn: Button = $HelpPanel/Margin/VBox/HelpCloseBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.pressed.connect(func(): resume_requested.emit())
	skip_btn.pressed.connect(_on_skip_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	help_btn.pressed.connect(_on_help_pressed)
	help_close_btn.pressed.connect(func(): help_panel.visible = false)
	help_panel.visible = false

func _on_skip_pressed() -> void:
	var summary := "You took a moment and skipped ahead. The community moved forward, and your journey continues safely."
	skip_requested.emit(summary)

func _on_settings_pressed() -> void:
	var settings_scene = load("res://scenes/menus/settings.tscn")
	if settings_scene:
		var inst = settings_scene.instantiate()
		add_child(inst)

func _on_help_pressed() -> void:
	help_panel.visible = !help_panel.visible
