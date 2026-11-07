extends Control

signal back_to_menu

@onready var messages_vbox: VBoxContainer = $ScrollContainer/MessagesVBox
@onready var back_btn: Button = $BackBtn
@onready var detail_panel: PanelContainer = $DetailPanel
@onready var detail_sender: Label = $DetailPanel/Margin/VBox/DetailSender
@onready var detail_text: Label = $DetailPanel/Margin/VBox/DetailText
@onready var detail_close_btn: Button = $DetailPanel/Margin/VBox/DetailCloseBtn

func _ready() -> void:
	back_btn.pressed.connect(func(): back_to_menu.emit())
	detail_close_btn.pressed.connect(func(): detail_panel.visible = false)
	detail_panel.visible = false
	populate_messages()

func populate_messages() -> void:
	for child in messages_vbox.get_children():
		child.queue_free()
		
	var sms_list = GameState.get_sms_list()
	if sms_list.size() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "Hakuna ujumbe (No messages)"
		empty_lbl.theme_override_colors/font_color = Color("#2B3320")
		messages_vbox.add_child(empty_lbl)
		return
		
	for i in range(sms_list.size()):
		var msg = sms_list[i]
		var item_btn := Button.new()
		var sender_str = msg.get("from", "Unknown")
		var text_str = msg.get("text", "")
		var preview = text_str.substr(0, 24) + "..."
		item_btn.text = "📨 %s:\n%s" % [sender_str, preview]
		item_btn.custom_minimum_size = Vector2(0, 60)
		item_btn.theme_override_colors/font_color = Color("#2B3320")
		item_btn.pressed.connect(func(): _open_detail(msg, i))
		messages_vbox.add_child(item_btn)

func _open_detail(msg: Dictionary, index: int) -> void:
	GameState.mark_sms_read(index)
	detail_sender.text = "Kutoka (From): " + msg.get("from", "Unknown")
	detail_text.text = msg.get("text", "")
	detail_panel.visible = true
