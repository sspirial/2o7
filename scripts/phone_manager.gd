class_name PhoneManager
extends RefCounted

static func process_ch1_phone_events() -> void:
	var path := "res://data/chapters/ch1_phone.json"
	if not FileAccess.file_exists(path):
		return
		
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
		
	var data: Dictionary = json.data
	var nodes: Array = data.get("nodes", [])
	var nodes_by_id: Dictionary = {}
	for n in nodes:
		nodes_by_id[n.get("node_id", "")] = n
		
	# 1. Mum SMS
	if nodes_by_id.has("sms_mum"):
		var text: String = nodes_by_id["sms_mum"].get("text", "")
		GameState.add_sms("Mum", text.replace("[SMS from Mum]: ", ""), "sms_1")
		
	# 2. Jabali SMS (based on matatu_choice)
	var matatu_choice = GameState.get_flag("matatu_choice", "listen")
	var jabali_node_id = "sms_jabali_" + str(matatu_choice)
	if nodes_by_id.has(jabali_node_id):
		var text: String = nodes_by_id[jabali_node_id].get("text", "")
		GameState.add_sms("Jabali", text.replace("[SMS from Jabali]: ", ""), "sms_2")
		
	# 3. Mama Achieng' SMS (based on kiosk_choice)
	var kiosk_choice = GameState.get_flag("kiosk_choice", "help")
	var mama_node_id = "sms_mama_" + str(kiosk_choice)
	if nodes_by_id.has(mama_node_id):
		var text: String = nodes_by_id[mama_node_id].get("text", "")
		GameState.add_sms("Mama Achieng'", text.replace("[SMS from Mama Achieng']: ", ""), "sms_3")
