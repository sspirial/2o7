extends Node

signal flag_changed(flag_name: String, new_value)
signal trust_changed(character: String, new_trust: int)
signal sms_received(message: Dictionary)

var player_name: String = "Baraka"
var player_gender: String = "male"
var current_chapter_id: String = "prologue"
var current_node_id: String = ""

# Story flags
var flags: Dictionary = {
	"matatu_choice": "listen",
	"kiosk_choice": "help",
	"prologue_choice": "good",
	"check_habit": false,
	"first_friend": ""
}

# Trust metrics per character
var trust: Dictionary = {
	"mama_achieng": 50,
	"jabali": 50,
	"mum": 80
}

# SMS Inbox
var sms_inbox: Array[Dictionary] = []

func _ready() -> void:
	print("[GameState] Initialized.")

func set_flag(flag_name: String, value) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)
	print("[GameState] Flag set: %s = %s" % [flag_name, str(value)])

func get_flag(flag_name: String, default_value = null):
	return flags.get(flag_name, default_value)

func add_trust(character: String, amount: int) -> void:
	var current: int = trust.get(character, 50)
	var new_val: int = clamp(current + amount, 0, 100)
	trust[character] = new_val
	trust_changed.emit(character, new_val)
	print("[GameState] Trust updated for %s: %d (%+d)" % [character, new_val, amount])

func get_trust(character: String) -> int:
	return trust.get(character, 50)

func add_sms(from_sender: String, message_text: String, msg_id: String = "") -> void:
	var new_sms := {
		"id": msg_id if msg_id != "" else str(sms_inbox.size() + 1),
		"from": from_sender,
		"text": message_text.replace("{player_name}", player_name),
		"read": false,
		"timestamp": "2007"
	}
	sms_inbox.append(new_sms)
	sms_received.emit(new_sms)
	print("[GameState] New SMS from %s received." % from_sender)

func get_sms_list() -> Array[Dictionary]:
	return sms_inbox

func mark_sms_read(index: int) -> void:
	if index >= 0 and index < sms_inbox.size():
		sms_inbox[index]["read"] = true

func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"player_gender": player_gender,
		"current_chapter_id": current_chapter_id,
		"current_node_id": current_node_id,
		"flags": flags,
		"trust": trust,
		"sms_inbox": sms_inbox
	}

func from_dict(data: Dictionary) -> void:
	player_name = data.get("player_name", "Baraka")
	player_gender = data.get("player_gender", "male")
	current_chapter_id = data.get("current_chapter_id", "prologue")
	current_node_id = data.get("current_node_id", "")
	flags = data.get("flags", {})
	trust = data.get("trust", {"mama_achieng": 50, "jabali": 50, "mum": 80})
	sms_inbox = []
	var saved_sms = data.get("sms_inbox", [])
	for s in saved_sms:
		sms_inbox.append(s)
	print("[GameState] State successfully loaded.")

func reset_state() -> void:
	player_name = "Baraka"
	player_gender = "male"
	current_chapter_id = "prologue"
	current_node_id = ""
	flags = {
		"matatu_choice": "listen",
		"kiosk_choice": "help",
		"prologue_choice": "good",
		"check_habit": false,
		"first_friend": ""
	}
	trust = {
		"mama_achieng": 50,
		"jabali": 50,
		"mum": 80
	}
	sms_inbox.clear()
