extends Control

signal destination_selected(destination_id: String)

@onready var stage7_btn: Button = $Locations/Stage7/Button
@onready var home_btn: Button = $Locations/Home/Button
@onready var kiosk_btn: Button = $Locations/Kiosk/Button
@onready var shusha_btn: Button = $ShushaBtn

func _ready() -> void:
	stage7_btn.pressed.connect(func(): destination_selected.emit("stage_7"))
	home_btn.pressed.connect(func(): _on_locked_node("Home (Umeshatoka hapa)"))
	kiosk_btn.pressed.connect(func(): _on_locked_node("Kiosk (Panda matatu kwanza kwenda Stage 7)"))
	shusha_btn.pressed.connect(func(): ShushaManager.open_shusha())

func _on_locked_node(msg: String) -> void:
	$InfoLabel.text = msg
