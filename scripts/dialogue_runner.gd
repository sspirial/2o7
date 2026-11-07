class_name DialogueRunner
extends Control

signal dialogue_finished(chapter_id: String)
signal node_changed(node_id: String)

@onready var speaker_label: Label = $DialoguePanel/Margin/VBox/SpeakerLabel
@onready var text_label: Label = $DialoguePanel/Margin/VBox/TextLabel
@onready var gloss_label: Label = $DialoguePanel/Margin/VBox/GlossLabel
@onready var choices_container: VBoxContainer = $ChoicesContainer
@onready var next_button: Button = $DialoguePanel/Margin/VBox/NextButton
@onready var name_input_container: VBoxContainer = $NameInputContainer
@onready var name_line_edit: LineEdit = $NameInputContainer/HBox/NameEdit
@onready var confirm_btn: Button = $NameInputContainer/HBox/ConfirmBtn
@onready var btn_baraka: Button = $NameInputContainer/PresetHBox/BtnBaraka
@onready var btn_neema: Button = $NameInputContainer/PresetHBox/BtnNeema
@onready var portrait_container: Control = $PortraitContainer
@onready var shusha_btn: Button = $ShushaBtn

var current_chapter: Dictionary = {}
var nodes_by_id: Dictionary = {}
var current_node: Dictionary = {}
var characters_data: Dictionary = {}

func _ready() -> void:
	load_characters()
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if name_input_container:
		name_input_container.visible = false
	if confirm_btn:
		confirm_btn.pressed.connect(func(): confirm_name(name_line_edit.text, "male"))
	if btn_baraka:
		btn_baraka.pressed.connect(func(): confirm_name("Baraka", "male"))
	if btn_neema:
		btn_neema.pressed.connect(func(): confirm_name("Neema", "female"))
	if shusha_btn:
		shusha_btn.pressed.connect(func(): ShushaManager.open_shusha())

func load_characters() -> void:
	var path := "res://data/characters/characters.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			characters_data = json.data

func load_chapter(chapter_path: String) -> bool:
	if not FileAccess.file_exists(chapter_path):
		push_error("[DialogueRunner] Chapter file not found: %s" % chapter_path)
		return false
		
	var file := FileAccess.open(chapter_path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("[DialogueRunner] JSON parse error in chapter: %s" % json.get_error_message())
		return false
		
	current_chapter = json.data
	nodes_by_id.clear()
	
	var nodes_arr: Array = current_chapter.get("nodes", [])
	for node in nodes_arr:
		var n_id: String = node.get("node_id", "")
		if n_id != "":
			nodes_by_id[n_id] = node
			
	if nodes_arr.size() > 0:
		display_node(nodes_arr[0].get("node_id", ""))
		return true
	return false

func display_node(node_id: String) -> void:
	if not nodes_by_id.has(node_id):
		print("[DialogueRunner] Node %s not found. Dialogue complete." % node_id)
		dialogue_finished.emit(current_chapter.get("chapter_id", ""))
		return
		
	current_node = nodes_by_id[node_id]
	GameState.current_node_id = node_id
	node_changed.emit(node_id)
	
	# Check for system branching
	if current_node.has("branches") and current_node["branches"] is Dictionary:
		var raw_text: String = current_node.get("text", "")
		var branch_key := ""
		if "matatu_choice" in raw_text:
			branch_key = "matatu_choice"
		elif "kiosk_choice" in raw_text:
			branch_key = "kiosk_choice"
		elif "prologue_choice" in raw_text:
			branch_key = "prologue_choice"
			
		var user_choice = GameState.get_flag(branch_key, "")
		var target_node = current_node["branches"].get(user_choice, null)
		if target_node:
			display_node(target_node)
			return
		else:
			var all_targets = current_node["branches"].values()
			if all_targets.size() > 0:
				display_node(all_targets[0])
				return

	# Handle meta / name entry
	if current_node.has("meta") and current_node["meta"].get("type") == "name_entry":
		show_name_entry_ui()
		return
	else:
		if name_input_container:
			name_input_container.visible = false

	# Setup speaker
	var speaker_id = current_node.get("speaker")
	if speaker_id != null and speaker_id != "":
		var char_info = characters_data.get(speaker_id, {})
		speaker_label.text = char_info.get("name", speaker_id.capitalize())
		speaker_label.visible = true
		_update_portrait(speaker_id)
	else:
		speaker_label.text = ""
		speaker_label.visible = false
		_clear_portrait()
		
	# Format text
	var raw_str: String = current_node.get("text", "")
	raw_str = raw_str.replace("{player_name}", GameState.player_name)
	text_label.text = raw_str
	
	# Gloss / translation note
	var gloss_str = current_node.get("gloss")
	if gloss_str != null and gloss_str != "":
		gloss_label.text = "💡 " + str(gloss_str).replace("{player_name}", GameState.player_name)
		gloss_label.visible = true
	else:
		gloss_label.text = ""
		gloss_label.visible = false

	# Choices or Next
	_clear_choices()
	var choices = current_node.get("choices")
	if choices != null and choices.size() > 0:
		next_button.visible = false
		for choice in choices:
			_create_choice_button(choice)
	else:
		next_button.visible = true

func _create_choice_button(choice_data: Dictionary) -> void:
	var btn := Button.new()
	btn.text = choice_data.get("text", "").replace("{player_name}", GameState.player_name)
	btn.custom_minimum_size = Vector2(0, 56)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.pressed.connect(func(): _on_choice_selected(choice_data))
	choices_container.add_child(btn)

func _on_choice_selected(choice_data: Dictionary) -> void:
	var effects: Dictionary = choice_data.get("effects", {})
	for key in effects.keys():
		if key == "trust_change" and effects[key] is Dictionary:
			for char_key in effects[key].keys():
				GameState.add_trust(char_key, effects[key][char_key])
		else:
			GameState.set_flag(key, effects[key])
			
	var next_node_id = choice_data.get("next")
	if next_node_id:
		display_node(next_node_id)
	else:
		dialogue_finished.emit(current_chapter.get("chapter_id", ""))

func _on_next_pressed() -> void:
	var next_node_id = current_node.get("next")
	if next_node_id != null and next_node_id != "":
		display_node(next_node_id)
	else:
		dialogue_finished.emit(current_chapter.get("chapter_id", ""))

func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()

func _update_portrait(speaker_id: String) -> void:
	_clear_portrait()
	var scene_path := "res://assets/characters/portrait_" + speaker_id + ".tscn"
	if ResourceLoader.exists(scene_path):
		var portrait_res = load(scene_path)
		var inst = portrait_res.instantiate()
		portrait_container.add_child(inst)

func _clear_portrait() -> void:
	for child in portrait_container.get_children():
		child.queue_free()

func show_name_entry_ui() -> void:
	speaker_label.visible = false
	_clear_portrait()
	text_label.text = "Choose your name to begin the journey:"
	gloss_label.visible = false
	next_button.visible = false
	_clear_choices()
	if name_input_container:
		name_input_container.visible = true

func confirm_name(chosen_name: String, gender: String = "male") -> void:
	if chosen_name.strip_edges() != "":
		GameState.player_name = chosen_name.strip_edges()
	GameState.player_gender = gender
	if name_input_container:
		name_input_container.visible = false
	var next_id = current_node.get("next", "")
	if next_id != "":
		display_node(next_id)
