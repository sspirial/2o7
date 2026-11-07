class_name GTACityGame
extends Node3D

const GTAAudio = preload("res://scripts/gta/gta_audio.gd")
const GTAMaterials = preload("res://scripts/gta/gta_materials.gd")
const CityBuilder = preload("res://scripts/gta/city_builder.gd")
const GTAMissions = preload("res://scripts/gta/gta_missions.gd")
const GTAHud = preload("res://scripts/gta/gta_hud.gd")
const Player3D = preload("res://scripts/gta/player_3d.gd")
const Vehicle3D = preload("res://scripts/gta/vehicle_3d.gd")
const Pedestrian3D = preload("res://scripts/gta/pedestrian_3d.gd")
const MissionMarker3D = preload("res://scripts/gta/mission_marker_3d.gd")

var player_scene: PackedScene = preload("res://scenes/gta/player_3d.tscn")
var vehicle_scene: PackedScene = preload("res://scenes/gta/vehicle_3d.tscn")
var ped_scene: PackedScene = preload("res://scenes/gta/pedestrian_3d.tscn")
var marker_scene: PackedScene = preload("res://scenes/gta/mission_marker_3d.tscn")
var hud_scene: PackedScene = preload("res://scenes/gta/gta_hud.tscn")

var city_builder: CityBuilder
var mission_manager: GTAMissions
var hud: GTAHud
var player: Player3D
var active_vehicle: Vehicle3D = null

var police_cruiser: Vehicle3D = null
var police_target_active: bool = false
var wanted_cooldown_timer: float = 0.0

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight

func _ready() -> void:
	_setup_inputs_if_needed()
	_setup_environment()
	_build_world()
	_spawn_player()
	_spawn_vehicles()
	_spawn_pedestrians()
	_spawn_mission_markers()
	_setup_hud()
	_setup_missions()

func _setup_inputs_if_needed() -> void:
	# Programmatic fallback for custom input actions to guarantee everything works
	var actions: Dictionary = {
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"sprint": [KEY_SHIFT],
		"interact": [KEY_F, KEY_E],
		"handbrake": [KEY_SPACE],
		"horn": [KEY_H],
		"radio": [KEY_R],
		"mouse_toggle": [KEY_M, KEY_TAB]
	}
	
	for action in actions.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for keycode in actions[action]:
				var ev := InputEventKey.new()
				ev.physical_keycode = keycode
				InputMap.action_add_event(action, ev)

func _setup_environment() -> void:
	if not world_env:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		add_child(world_env)
		
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.25, 0.45, 0.85)
	sky_mat.sky_horizon_color = Color(0.85, 0.72, 0.6)
	sky_mat.ground_bottom_color = Color(0.12, 0.12, 0.15)
	sky_mat.ground_horizon_color = Color(0.75, 0.65, 0.55)
	sky_mat.sun_angle_max = 30.0
	sky.sky_material = sky_mat
	env.sky = sky
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.15
	world_env.environment = env
	
	if not sun_light:
		sun_light = DirectionalLight3D.new()
		sun_light.name = "SunLight"
		sun_light.rotation_degrees = Vector3(-42.0, -45.0, 0.0)
		sun_light.light_color = Color(1.0, 0.96, 0.88)
		sun_light.light_energy = 1.3
		sun_light.shadow_enabled = true
		add_child(sun_light)

func _build_world() -> void:
	city_builder = CityBuilder.new()
	city_builder.name = "City"
	add_child(city_builder)
	city_builder.build_city()

func _spawn_player() -> void:
	player = player_scene.instantiate() as Player3D
	player.position = Vector3(26.0, 0.5, -18.0)
	player.rotation.y = PI
	add_child(player)
	
	player.entered_vehicle.connect(_on_player_entered_vehicle)
	player.exited_vehicle.connect(_on_player_exited_vehicle)
	player.died.connect(_on_player_died)

func _spawn_vehicles() -> void:
	# 1. Iconic Matatu "The Flash" at Stage 7 Terminus
	var matatu := vehicle_scene.instantiate() as Vehicle3D
	matatu.vehicle_type = Vehicle3D.VehicleType.MATATU
	matatu.position = Vector3(30.0, 0.5, -25.0)
	matatu.rotation.y = PI * 0.5
	add_child(matatu)
	
	# 2. Nairobi Taxi Cab
	var taxi := vehicle_scene.instantiate() as Vehicle3D
	taxi.vehicle_type = Vehicle3D.VehicleType.TAXI
	taxi.position = Vector3(-60.0, 0.5, 12.0)
	add_child(taxi)
	
	# 3. Muscle Sports Car (Runner GT)
	var muscle := vehicle_scene.instantiate() as Vehicle3D
	muscle.vehicle_type = Vehicle3D.VehicleType.MUSCLE
	muscle.position = Vector3(-12.0, 0.5, 0.0)
	add_child(muscle)
	
	# 4. Police Interceptor Cruiser
	police_cruiser = vehicle_scene.instantiate() as Vehicle3D
	police_cruiser.vehicle_type = Vehicle3D.VehicleType.POLICE
	police_cruiser.position = Vector3(60.0, 0.5, -45.0)
	police_cruiser.rotation.y = PI
	add_child(police_cruiser)

func _spawn_pedestrians() -> void:
	# Spawn several pedestrians on sidewalks
	var sidewalk_routes: Array[Array] = [
		[Vector3(12, 0.3, 10), Vector3(50, 0.3, 10), Vector3(50, 0.3, 50), Vector3(12, 0.3, 50)],
		[Vector3(-50, 0.3, -10), Vector3(-12, 0.3, -10), Vector3(-12, 0.3, -50), Vector3(-50, 0.3, -50)],
		[Vector3(12, 0.3, -10), Vector3(45, 0.3, -10), Vector3(45, 0.3, -25), Vector3(12, 0.3, -25)],
		[Vector3(-45, 0.3, 10), Vector3(-15, 0.3, 10), Vector3(-15, 0.3, 50), Vector3(-45, 0.3, 50)]
	]
	
	for route in sidewalk_routes:
		var ped := ped_scene.instantiate() as Pedestrian3D
		ped.position = route[0]
		ped.set_patrol_path(route)
		ped.pedestrian_hit.connect(_on_pedestrian_hit)
		add_child(ped)

func _spawn_mission_markers() -> void:
	# Mission 1: Matatu Rush at Stage 7
	var m1 := marker_scene.instantiate() as MissionMarker3D
	m1.position = Vector3(36.0, 0.2, -32.0)
	m1.mission_id = 1
	m1.marker_color = Color(1.0, 0.85, 0.1)
	m1.mission_marker_triggered.connect(_on_mission_marker_triggered)
	add_child(m1)
	
	# Mission 2: Checkpoint Blitz at Downtown Plaza
	var m2 := marker_scene.instantiate() as MissionMarker3D
	m2.position = Vector3(-25.0, 0.2, 25.0)
	m2.mission_id = 2
	m2.marker_color = Color(0.2, 0.85, 1.0)
	m2.mission_marker_triggered.connect(_on_mission_marker_triggered)
	add_child(m2)
	
	# Mission 3: Evade Pursuit at Industrial Block
	var m3 := marker_scene.instantiate() as MissionMarker3D
	m3.position = Vector3(65.0, 0.2, 55.0)
	m3.mission_id = 3
	m3.marker_color = Color(1.0, 0.25, 0.25)
	m3.mission_marker_triggered.connect(_on_mission_marker_triggered)
	add_child(m3)

func _setup_hud() -> void:
	hud = hud_scene.instantiate() as GTAHud
	add_child(hud)
	hud.set_player(player)

func _setup_missions() -> void:
	mission_manager = GTAMissions.new()
	mission_manager.name = "MissionManager"
	add_child(mission_manager)
	
	mission_manager.mission_started.connect(_on_mission_started)
	mission_manager.mission_passed.connect(_on_mission_passed)
	mission_manager.mission_failed.connect(_on_mission_failed)
	mission_manager.wanted_level_requested.connect(func(stars): hud.set_wanted_level(stars))

func _on_player_entered_vehicle(veh: Node) -> void:
	active_vehicle = veh as Vehicle3D
	hud.set_current_vehicle(veh)
	if veh.has_signal("radio_station_changed"):
		if not veh.radio_station_changed.is_connected(hud.show_radio_station):
			veh.radio_station_changed.connect(hud.show_radio_station)

func _on_player_exited_vehicle() -> void:
	active_vehicle = null
	hud.set_current_vehicle(null)

func _on_pedestrian_hit(_ped: Node) -> void:
	# Hitting pedestrians raises wanted level GTA-style!
	var current_stars: int = hud.wanted_stars
	hud.set_wanted_level(current_stars + 1)
	police_target_active = true

func _on_mission_marker_triggered(m_id: int) -> void:
	if mission_manager.current_mission == GTAMissions.MissionId.NONE:
		mission_manager.start_mission(m_id as GTAMissions.MissionId)

func _on_mission_started(title: String, instruction: String, time_limit: float) -> void:
	hud.objective_pos = mission_manager.get_current_objective_pos()
	hud.show_mission_active(title, instruction, time_limit)

func _on_mission_passed(reward: int, title: String) -> void:
	hud.objective_pos = Vector3.ZERO
	hud.show_mission_passed(reward, title)

func _on_mission_failed(reason: String) -> void:
	hud.objective_pos = Vector3.ZERO
	hud.show_mission_failed(reason)

func _on_player_died() -> void:
	# Trigger GTA "WASTED" sequence
	hud.show_mission_failed("WASTED")
	Engine.time_scale = 0.35
	await get_tree().create_timer(1.2).timeout
	Engine.time_scale = 1.0
	
	# Respawn at Stage 7
	if active_vehicle:
		player.exit_vehicle()
	player.position = Vector3(26.0, 0.5, -18.0)
	player.current_health = player.max_health
	player.emit_signal("health_changed", player.current_health, player.max_health)
	hud.set_wanted_level(0)

func _physics_process(delta: float) -> void:
	# Track player position for missions
	var cur_pos: Vector3 = player.global_position if not active_vehicle else active_vehicle.global_position
	mission_manager.check_player_position(cur_pos)
	
	if mission_manager.current_mission != GTAMissions.MissionId.NONE:
		hud.objective_pos = mission_manager.get_current_objective_pos()
		hud.show_mission_active(mission_manager.mission_title, mission_manager.mission_instruction, mission_manager.mission_timer)
		
	# Police pursuit AI if wanted
	_process_police_ai(delta, cur_pos)
	
	# Reset vehicle if overturned (Backspace key)
	if Input.is_key_pressed(KEY_BACKSPACE) and active_vehicle:
		active_vehicle.rotation.x = 0.0
		active_vehicle.rotation.z = 0.0
		active_vehicle.global_position.y += 1.0

func _process_police_ai(delta: float, target_pos: Vector3) -> void:
	if not police_cruiser or hud.wanted_stars == 0:
		if police_cruiser and police_cruiser.siren_active:
			police_cruiser.siren_active = false
		return
		
	police_cruiser.siren_active = true
	var diff: Vector3 = target_pos - police_cruiser.global_position
	diff.y = 0.0
	var dist: float = diff.length()
	
	if dist > 6.0:
		var dir: Vector3 = diff.normalized()
		var target_angle: float = atan2(-dir.x, -dir.z)
		police_cruiser.rotation.y = lerp_angle(police_cruiser.rotation.y, target_angle, 3.5 * delta)
		police_cruiser.forward_speed = minf(police_cruiser.forward_speed + 16.0 * delta, 26.0)
		var horiz: Vector3 = -police_cruiser.global_transform.basis.z * police_cruiser.forward_speed
		police_cruiser.velocity.x = horiz.x
		police_cruiser.velocity.z = horiz.z
	else:
		# Close to player: attempt pit maneuver
		police_cruiser.forward_speed = move_toward(police_cruiser.forward_speed, 8.0, 10.0 * delta)
		if dist < 3.5 and not active_vehicle:
			player.take_damage(15.0 * delta)
			
	# Wanted level cooldown when out of range
	if dist > 80.0:
		wanted_cooldown_timer += delta
		if wanted_cooldown_timer > 15.0:
			wanted_cooldown_timer = 0.0
			hud.set_wanted_level(hud.wanted_stars - 1)
	else:
		wanted_cooldown_timer = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_M or event.keycode == KEY_TAB):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			if player: player.mouse_captured = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if player: player.mouse_captured = true
			
	# Quick warp keys for testing (1 = Player, 2 = Matatu, 3 = Muscle)
	if event is InputEventKey and event.pressed and event.keycode == KEY_1:
		if active_vehicle:
			player.exit_vehicle()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_2:
		var matatu := get_tree().get_first_node_in_group("vehicles")
		if matatu and not active_vehicle:
			player.enter_vehicle(matatu)
