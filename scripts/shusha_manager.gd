extends Node

signal shusha_opened
signal shusha_closed
signal scene_skipped(summary: String)

var is_paused: bool = false
var pause_instance: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_shusha()

func toggle_shusha() -> void:
	if is_paused:
		close_shusha()
	else:
		open_shusha()

func open_shusha() -> void:
	if is_paused:
		return
	is_paused = true
	get_tree().paused = true
	
	if pause_instance == null:
		var scene_res = load("res://scenes/menus/pause_shusha.tscn")
		if scene_res:
			pause_instance = scene_res.instantiate()
			add_child(pause_instance)
			if pause_instance.has_signal("resume_requested"):
				pause_instance.connect("resume_requested", Callable(self, "close_shusha"))
			if pause_instance.has_signal("skip_requested"):
				pause_instance.connect("skip_requested", Callable(self, "_on_skip_requested"))
	else:
		pause_instance.visible = true
		
	shusha_opened.emit()
	print("[ShushaManager] Shusha safety pause opened.")

func close_shusha() -> void:
	if not is_paused:
		return
	is_paused = false
	get_tree().paused = false
	if pause_instance:
		pause_instance.visible = false
	shusha_closed.emit()
	print("[ShushaManager] Shusha closed, resumed.")

func _on_skip_requested(summary: String) -> void:
	close_shusha()
	scene_skipped.emit(summary)
	print("[ShushaManager] Scene skipped with summary: %s" % summary)
