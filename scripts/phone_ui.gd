extends Control

signal phone_closed

@onready var menu_container: VBoxContainer = $PhoneFrame/LcdBezel/LcdScreen/MenuVBox
@onready var inbox_container: Control = $PhoneFrame/LcdBezel/LcdScreen/InboxContainer
@onready var messages_btn: Button = $PhoneFrame/LcdBezel/LcdScreen/MenuVBox/MessagesBtn
@onready var mpesa_btn: Button = $PhoneFrame/LcdBezel/LcdScreen/MenuVBox/MpesaBtn
@onready var nyoka_btn: Button = $PhoneFrame/LcdBezel/LcdScreen/MenuVBox/NyokaBtn
@onready var kumbukumbu_btn: Button = $PhoneFrame/LcdBezel/LcdScreen/MenuVBox/KumbukumbuBtn
@onready var close_phone_btn: Button = $ClosePhoneBtn
@onready var shusha_btn: Button = $ShushaBtn
@onready var status_lbl: Label = $PhoneFrame/LcdBezel/LcdScreen/StatusLabel

var inbox_scene_inst: Control = null

func _ready() -> void:
	messages_btn.pressed.connect(_on_messages_pressed)
	mpesa_btn.pressed.connect(func(): _show_status("M-PESA: Salio KSh 450. Hakuna deni."))
	nyoka_btn.pressed.connect(func(): _show_status("NYOKA: Inakuja hivi karibuni! (Coming soon)"))
	kumbukumbu_btn.pressed.connect(func(): _show_status("KUMBUKUMBU: 2 cards unlocked."))
	close_phone_btn.pressed.connect(func(): phone_closed.emit())
	shusha_btn.pressed.connect(func(): ShushaManager.open_shusha())
	
	_load_inbox()
	_update_badge()

func _update_badge() -> void:
	var total = GameState.get_sms_list().size()
	messages_btn.text = "📨 Ujumbe (SMS) [%d]" % total

func _load_inbox() -> void:
	var inbox_res = load("res://scenes/phone/sms_inbox.tscn")
	if inbox_res:
		inbox_scene_inst = inbox_res.instantiate()
		inbox_container.add_child(inbox_scene_inst)
		inbox_scene_inst.visible = false
		inbox_scene_inst.connect("back_to_menu", Callable(self, "_on_back_from_inbox"))

func _on_messages_pressed() -> void:
	menu_container.visible = false
	status_lbl.visible = false
	if inbox_scene_inst:
		inbox_scene_inst.visible = true
		if inbox_scene_inst.has_method("populate_messages"):
			inbox_scene_inst.populate_messages()

func _on_back_from_inbox() -> void:
	if inbox_scene_inst:
		inbox_scene_inst.visible = false
	menu_container.visible = true
	status_lbl.visible = true
	_update_badge()

func _show_status(msg: String) -> void:
	status_lbl.text = msg
