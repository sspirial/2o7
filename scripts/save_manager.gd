extends Node

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1

func save_game() -> bool:
	var state_data: Dictionary = GameState.to_dict()
	var full_save := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"game_state": state_data
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] Failed to open save file for writing: %s" % SAVE_PATH)
		return false
		
	var json_string := JSON.stringify(full_save, "  ")
	file.store_string(json_string)
	file.close()
	print("[SaveManager] Game saved successfully.")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] No save file found.")
		return false
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Failed to open save file for reading.")
		return false
		
	var content := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(content)
	if parse_result != OK:
		push_error("[SaveManager] Corrupt save file: %s" % json.get_error_message())
		return false
		
	var data: Dictionary = json.data
	if data.has("game_state"):
		GameState.from_dict(data["game_state"])
		print("[SaveManager] Game state loaded from save.")
		return true
		
	return false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveManager] Save deleted.")
