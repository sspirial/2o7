class_name SceneRouter
extends Node

@onready var scene_container: Node = $SceneContainer
@onready var fade_overlay: ColorRect = $FadeOverlay

var current_scene_node: Node = null

enum GameStage {
	TITLE,
	CONTENT_NOTICE,
	PROLOGUE_DIALOGUE,
	MTAA_MAP,
	MATATU_RIDE,
	KIOSK_SCENE,
	PHONE_SCREEN,
	END_SCREEN
}

var current_stage: GameStage = GameStage.TITLE

func _ready() -> void:
	if fade_overlay:
		fade_overlay.color = Color(0.102, 0.106, 0.255, 0.0)
		fade_overlay.visible = false
	go_to_stage(GameStage.TITLE)

func go_to_stage(stage: GameStage) -> void:
	current_stage = stage
	match stage:
		GameStage.TITLE:
			_switch_scene("res://scenes/main/title_screen.tscn", _on_title_loaded)
		GameStage.CONTENT_NOTICE:
			_switch_scene("res://scenes/main/content_notice.tscn", _on_content_notice_loaded)
		GameStage.PROLOGUE_DIALOGUE:
			_switch_scene("res://scenes/dialogue/dialogue_scene.tscn", _on_prologue_loaded)
		GameStage.MTAA_MAP:
			_switch_scene("res://scenes/map/mtaa_map.tscn", _on_map_loaded)
		GameStage.MATATU_RIDE:
			_switch_scene("res://scenes/matatu/matatu_ride.tscn", _on_matatu_loaded)
		GameStage.KIOSK_SCENE:
			_switch_scene("res://scenes/kiosk/kiosk_scene.tscn", _on_kiosk_loaded)
		GameStage.PHONE_SCREEN:
			PhoneManager.process_ch1_phone_events()
			_switch_scene("res://scenes/phone/phone.tscn", _on_phone_loaded)
		GameStage.END_SCREEN:
			_switch_scene("res://scenes/end/end_screen.tscn", _on_end_loaded)

func _switch_scene(scene_path: String, on_ready_callback: Callable = Callable()) -> void:
	if fade_overlay:
		fade_overlay.visible = true
		var tween := create_tween()
		tween.tween_property(fade_overlay, "color:a", 1.0, 0.25)
		await tween.finished
		
	# Clean up previous scene
	if current_scene_node:
		current_scene_node.queue_free()
		current_scene_node = null
		
	var scene_res = load(scene_path)
	if scene_res:
		current_scene_node = scene_res.instantiate()
		scene_container.add_child(current_scene_node)
		if on_ready_callback.is_valid():
			on_ready_callback.call(current_scene_node)
			
	if fade_overlay:
		var tween_out := create_tween()
		tween_out.tween_property(fade_overlay, "color:a", 0.0, 0.25)
		await tween_out.finished
		fade_overlay.visible = false

# Stage Callbacks
func _on_title_loaded(node: Node) -> void:
	if node.has_signal("start_requested"):
		node.connect("start_requested", Callable(self, "_on_title_start"))

func _on_title_start() -> void:
	go_to_stage(GameStage.CONTENT_NOTICE)

func _on_content_notice_loaded(node: Node) -> void:
	if node.has_signal("accepted"):
		node.connect("accepted", Callable(self, "_on_notice_accepted"))

func _on_notice_accepted() -> void:
	go_to_stage(GameStage.PROLOGUE_DIALOGUE)

func _on_prologue_loaded(node: Node) -> void:
	if node is DialogueRunner:
		node.load_chapter("res://data/chapters/prologue.json")
		node.dialogue_finished.connect(func(_chap): go_to_stage(GameStage.MTAA_MAP))

func _on_map_loaded(node: Node) -> void:
	if node.has_signal("destination_selected"):
		node.connect("destination_selected", Callable(self, "_on_destination_chosen"))

func _on_destination_chosen(dest_id: String) -> void:
	if dest_id == "stage_7" or dest_id == "matatu":
		go_to_stage(GameStage.MATATU_RIDE)
	elif dest_id == "kiosk":
		go_to_stage(GameStage.KIOSK_SCENE)

func _on_matatu_loaded(node: Node) -> void:
	if node.has_signal("matatu_ride_completed"):
		node.connect("matatu_ride_completed", func(): go_to_stage(GameStage.KIOSK_SCENE))

func _on_kiosk_loaded(node: Node) -> void:
	if node.has_signal("kiosk_scene_completed"):
		node.connect("kiosk_scene_completed", func(): go_to_stage(GameStage.PHONE_SCREEN))

func _on_phone_loaded(node: Node) -> void:
	if node.has_signal("phone_closed"):
		node.connect("phone_closed", func(): go_to_stage(GameStage.END_SCREEN))

func _on_end_loaded(node: Node) -> void:
	if node.has_signal("restart_requested"):
		node.connect("restart_requested", func():
			GameState.reset_state()
			go_to_stage(GameStage.TITLE)
		)
