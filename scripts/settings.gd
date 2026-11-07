extends Control

@onready var close_btn: Button = $PanelContainer/MarginContainer/VBox/BackButton
@onready var sound_check: CheckBox = $PanelContainer/MarginContainer/VBox/SoundBox/CheckBox
@onready var quiet_mode_check: CheckBox = $PanelContainer/MarginContainer/VBox/QuietBox/CheckBox
@onready var text_slider: HSlider = $PanelContainer/MarginContainer/VBox/TextSizeBox/HSlider
@onready var language_btn: OptionButton = $PanelContainer/MarginContainer/VBox/LangBox/OptionButton

const SETTINGS_FILE := "user://settings.cfg"

func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)
	_load_settings()

func _load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE)
	if err == OK:
		sound_check.button_pressed = config.get_value("audio", "sound_enabled", true)
		quiet_mode_check.button_pressed = config.get_value("accessibility", "quiet_mode", false)
		text_slider.value = config.get_value("display", "text_scale", 1.0)
	else:
		sound_check.button_pressed = true
		quiet_mode_check.button_pressed = false
		text_slider.value = 1.0

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "sound_enabled", sound_check.button_pressed)
	config.set_value("accessibility", "quiet_mode", quiet_mode_check.button_pressed)
	config.set_value("display", "text_scale", text_slider.value)
	config.save(SETTINGS_FILE)

func _on_close_pressed() -> void:
	_save_settings()
	queue_free()
