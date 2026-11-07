class_name GTAMissions
extends Node

const GTAAudio = preload("res://scripts/gta/gta_audio.gd")
const GTAMaterials = preload("res://scripts/gta/gta_materials.gd")

enum MissionId {
	NONE,
	MATATU_RUSH,
	CHECKPOINT_BLITZ,
	EVADE_THE_HEAT
}

var current_mission: MissionId = MissionId.NONE
var mission_timer: float = 0.0
var active_checkpoints: Array[Vector3] = []
var current_checkpoint_idx: int = 0
var target_destination: Vector3 = Vector3.ZERO
var mission_title: String = ""
var mission_instruction: String = ""

# Audio player for fanfare
var fanfare_player: AudioStreamPlayer

signal mission_started(title: String, instruction: String, time_limit: float)
signal mission_passed(reward_cash: int, title: String)
signal mission_failed(reason: String)
signal mission_checkpoint_reached(remaining: int)
signal wanted_level_requested(stars: int)

func _ready() -> void:
	fanfare_player = AudioStreamPlayer.new()
	fanfare_player.name = "FanfarePlayer"
	fanfare_player.stream = GTAAudio.get_jingle_stream()
	fanfare_player.volume_db = -4.0
	add_child(fanfare_player)

func start_mission(id: MissionId) -> void:
	current_mission = id
	match id:
		MissionId.MATATU_RUSH:
			mission_title = "MATATU RUSH: STAGE 7"
			mission_instruction = "Pick up commuters at Stage 7 and speed to Nairobi Central!"
			mission_timer = 65.0
			target_destination = Vector3(-60.0, 0.0, 60.0)
			active_checkpoints = [target_destination]
			current_checkpoint_idx = 0
			emit_signal("mission_started", mission_title, mission_instruction, mission_timer)
			
		MissionId.CHECKPOINT_BLITZ:
			mission_title = "CHECKPOINT BLITZ"
			mission_instruction = "Speed through all 4 checkpoints across Nairobi before time expires!"
			mission_timer = 50.0
			active_checkpoints = [
				Vector3(-60.0, 0.0, -60.0),
				Vector3(0.0, 0.0, 0.0),
				Vector3(60.0, 0.0, -60.0),
				Vector3(60.0, 0.0, 60.0)
			]
			current_checkpoint_idx = 0
			emit_signal("mission_started", mission_title, mission_instruction, mission_timer)
			
		MissionId.EVADE_THE_HEAT:
			mission_title = "EVADE THE HEAT"
			mission_instruction = "Survive the 3-Star Police Pursuit for 45 seconds to lose the heat!"
			mission_timer = 45.0
			active_checkpoints = []
			emit_signal("wanted_level_requested", 3)
			emit_signal("mission_started", mission_title, mission_instruction, mission_timer)

func _process(delta: float) -> void:
	if current_mission == MissionId.NONE:
		return
		
	mission_timer -= delta
	if mission_timer <= 0.0:
		fail_mission("TIME EXPIRED!")
		return

func check_player_position(pos: Vector3) -> void:
	if current_mission == MissionId.NONE:
		return
		
	if current_mission == MissionId.EVADE_THE_HEAT:
		if mission_timer <= 0.0:
			pass_mission(2000)
		return
		
	if active_checkpoints.is_empty():
		return
		
	var target := active_checkpoints[current_checkpoint_idx]
	var dist := Vector2(pos.x - target.x, pos.z - target.z).length()
	if dist < 8.0:
		current_checkpoint_idx += 1
		if current_checkpoint_idx >= active_checkpoints.size():
			var reward: int = 800 if current_mission == MissionId.MATATU_RUSH else 1200
			pass_mission(reward)
		else:
			var remaining := active_checkpoints.size() - current_checkpoint_idx
			emit_signal("mission_checkpoint_reached", remaining)

func pass_mission(reward_cash: int) -> void:
	var passed_title := mission_title
	current_mission = MissionId.NONE
	active_checkpoints.clear()
	
	if fanfare_player:
		fanfare_player.play()
		
	emit_signal("mission_passed", reward_cash, passed_title)

func fail_mission(reason: String) -> void:
	current_mission = MissionId.NONE
	active_checkpoints.clear()
	emit_signal("mission_failed", reason)

func get_current_objective_pos() -> Vector3:
	if current_mission != MissionId.NONE and current_checkpoint_idx < active_checkpoints.size():
		return active_checkpoints[current_checkpoint_idx]
	return Vector3.ZERO
