class_name Vehicle3D
extends CharacterBody3D

const GTAAudio = preload("res://scripts/gta/gta_audio.gd")
const GTAMaterials = preload("res://scripts/gta/gta_materials.gd")

enum VehicleType {
	MATATU,
	TAXI,
	MUSCLE,
	POLICE
}

@export var vehicle_type: VehicleType = VehicleType.MATATU
@export var vehicle_name: String = "Matatu 'The Flash'"
@export var max_speed: float = 30.0 # m/s (~108 km/h)
@export var acceleration: float = 18.0
@export var brake_force: float = 24.0
@export var reverse_speed: float = 12.0
@export var steer_speed: float = 2.4
@export var max_steer_angle: float = 0.55 # radians
@export var drift_friction: float = 0.92
@export var normal_friction: float = 0.98

var is_driven: bool = false
var driver_ref: Node = null
var current_steer_angle: float = 0.0
var forward_speed: float = 0.0
var health: float = 100.0

# Radio system
var current_station: int = 0
var station_names: Array[String] = [
	"Radio 254 (Afrobeats & Benga)",
	"Nairobi Night (Synthwave 80s)",
	"Ghetto Heat 92.5 (Hip-Hop & Drill)",
	"Radio Off"
]

# Audio players
var engine_audio: AudioStreamPlayer
var screech_audio: AudioStreamPlayer
var horn_audio: AudioStreamPlayer
var radio_audio: AudioStreamPlayer
var siren_audio: AudioStreamPlayer

# Node references
@onready var chase_camera_rig: Node3D = $ChaseCameraRig
@onready var chase_camera: Camera3D = $ChaseCameraRig/SpringArm3D/Camera3D
@onready var chase_spring_arm: SpringArm3D = $ChaseCameraRig/SpringArm3D
@onready var body_mesh: Node3D = $BodyVisuals
@onready var front_left_wheel: Node3D = $BodyVisuals/FrontLeftWheel
@onready var front_right_wheel: Node3D = $BodyVisuals/FrontRightWheel
@onready var rear_left_wheel: Node3D = $BodyVisuals/RearLeftWheel
@onready var rear_right_wheel: Node3D = $BodyVisuals/RearRightWheel
@onready var headlights: Node3D = $BodyVisuals/Headlights
@onready var brake_lights: Node3D = $BodyVisuals/BrakeLights
@onready var siren_lights: Node3D = $BodyVisuals/SirenLights

var siren_timer: float = 0.0
var siren_active: bool = false
var is_drifting: bool = false
var wheel_spin: float = 0.0

signal vehicle_damaged(amount: float)
signal radio_station_changed(station_name: String)

func _ready() -> void:
	add_to_group("vehicles")
	_setup_audio()
	_apply_vehicle_styling()

func _setup_audio() -> void:
	engine_audio = AudioStreamPlayer.new()
	engine_audio.name = "EngineAudio"
	engine_audio.stream = GTAAudio.get_engine_stream()
	engine_audio.volume_db = -8.0
	add_child(engine_audio)
	
	screech_audio = AudioStreamPlayer.new()
	screech_audio.name = "ScreechAudio"
	screech_audio.stream = GTAAudio.get_screech_stream()
	screech_audio.volume_db = -12.0
	add_child(screech_audio)
	
	horn_audio = AudioStreamPlayer.new()
	horn_audio.name = "HornAudio"
	horn_audio.stream = GTAAudio.get_horn_stream()
	horn_audio.volume_db = -4.0
	add_child(horn_audio)
	
	radio_audio = AudioStreamPlayer.new()
	radio_audio.name = "RadioAudio"
	radio_audio.volume_db = -6.0
	add_child(radio_audio)
	
	if vehicle_type == VehicleType.POLICE:
		siren_audio = AudioStreamPlayer.new()
		siren_audio.name = "SirenAudio"
		siren_audio.stream = GTAAudio.get_siren_stream()
		siren_audio.volume_db = -4.0
		add_child(siren_audio)

func _apply_vehicle_styling() -> void:
	var chassis_mesh_inst: MeshInstance3D = null
	if body_mesh:
		chassis_mesh_inst = body_mesh.get_node_or_null("ChassisMesh")
		
	match vehicle_type:
		VehicleType.MATATU:
			vehicle_name = "Matatu 'The Flash'"
			max_speed = 31.0
			acceleration = 19.0
			if chassis_mesh_inst:
				chassis_mesh_inst.material_override = GTAMaterials.get_matatu_material()
		VehicleType.TAXI:
			vehicle_name = "Nairobi Cab 'Stage 7'"
			max_speed = 34.0
			acceleration = 22.0
			if chassis_mesh_inst:
				chassis_mesh_inst.material_override = GTAMaterials.get_taxi_material()
		VehicleType.MUSCLE:
			vehicle_name = "Nairobi Runner GT"
			max_speed = 44.0
			acceleration = 28.0
			if chassis_mesh_inst:
				chassis_mesh_inst.material_override = GTAMaterials.get_muscle_material()
		VehicleType.POLICE:
			vehicle_name = "Police Interceptor"
			max_speed = 38.0
			acceleration = 24.0
			if chassis_mesh_inst:
				chassis_mesh_inst.material_override = GTAMaterials.get_police_material()

func mount_driver(player: Node) -> void:
	driver_ref = player
	is_driven = true
	
	if chase_camera:
		chase_camera.current = true
		
	if engine_audio and not engine_audio.playing:
		engine_audio.play()
		
	# Start radio on vehicle entry if not off
	if current_station < 3:
		_play_radio_station()
		
	# Play door sound
	var door_stream := GTAAudio.get_door_stream()
	var ap := AudioStreamPlayer.new()
	ap.stream = door_stream
	add_child(ap)
	ap.play()
	ap.finished.connect(ap.queue_free)

func unmount_driver() -> void:
	is_driven = false
	driver_ref = null
	
	if chase_camera:
		chase_camera.current = false
		
	if engine_audio and engine_audio.playing:
		engine_audio.stop()
		
	if screech_audio and screech_audio.playing:
		screech_audio.stop()
		
	if radio_audio and radio_audio.playing:
		radio_audio.stop()
		
	if siren_audio and siren_audio.playing:
		siren_audio.stop()
		
	var door_stream := GTAAudio.get_door_stream()
	var ap := AudioStreamPlayer.new()
	ap.stream = door_stream
	add_child(ap)
	ap.play()
	ap.finished.connect(ap.queue_free)

func get_exit_position() -> Vector3:
	# Exit to left side of car
	return global_transform.origin - global_transform.basis.x * 2.2 + Vector3.UP * 0.3

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	elif velocity.y < 0.0:
		velocity.y = -0.5
		
	if is_driven:
		_handle_driver_input(delta)
	else:
		_handle_parked_physics(delta)
		
	move_and_slide()
	
	# Update collision responses
	_check_collisions()
	
	# Visual updates
	_update_visuals(delta)

func _handle_driver_input(delta: float) -> void:
	var forward_input: float = 0.0
	if Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		forward_input += 1.0
	if Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		forward_input -= 1.0
		
	var steer_input: float = 0.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer_input += 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer_input -= 1.0
		
	var handbrake: bool = Input.is_action_pressed("handbrake") or Input.is_key_pressed(KEY_SPACE)
	
	# Exit vehicle check
	if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_F) or Input.is_key_pressed(KEY_E):
		# Prevent immediate exit on frame 0
		if driver_ref and driver_ref.has_method("exit_vehicle"):
			driver_ref.exit_vehicle()
			return
			
	# Horn check
	if Input.is_action_just_pressed("horn") or Input.is_key_pressed(KEY_H):
		if horn_audio and not horn_audio.playing:
			horn_audio.play()
			
	# Radio toggle check
	if Input.is_action_just_pressed("radio") or Input.is_key_pressed(KEY_R):
		_cycle_radio()
		
	# Siren toggle for police
	if vehicle_type == VehicleType.POLICE and (Input.is_key_pressed(KEY_1) or Input.is_key_pressed(KEY_C)):
		siren_active = not siren_active
		if siren_audio:
			if siren_active: siren_audio.play()
			else: siren_audio.stop()
			
	# Steering calculation
	var target_steer: float = steer_input * max_steer_angle
	current_steer_angle = lerpf(current_steer_angle, target_steer, steer_speed * 4.0 * delta)
	
	# Longitudinal velocity
	var car_forward := -global_transform.basis.z
	var car_right := global_transform.basis.x
	
	forward_speed = velocity.dot(car_forward)
	var lateral_speed: float = velocity.dot(car_right)
	
	if forward_input > 0.0:
		forward_speed += acceleration * forward_input * delta
		forward_speed = minf(forward_speed, max_speed)
	elif forward_input < 0.0:
		if forward_speed > 1.0:
			# Braking
			forward_speed -= brake_force * delta
		else:
			# Reversing
			forward_speed -= acceleration * 0.7 * delta
			forward_speed = maxf(forward_speed, -reverse_speed)
	else:
		# Coasting drag
		forward_speed = move_toward(forward_speed, 0.0, 6.0 * delta)
		
	# Handbrake drift logic
	is_drifting = handbrake and abs(forward_speed) > 5.0
	if handbrake:
		forward_speed = move_toward(forward_speed, 0.0, brake_force * 0.7 * delta)
		
	var friction: float = drift_friction if is_drifting else normal_friction
	lateral_speed *= pow(friction, delta * 60.0)
	
	# Turning rotation
	var speed_ratio: float = clampf(abs(forward_speed) / 10.0, 0.0, 1.0)
	if abs(forward_speed) > 0.5:
		var dir_mult: float = 1.0 if forward_speed > 0.0 else -1.0
		var drift_mult: float = 1.6 if is_drifting else 1.0
		var yaw_rate: float = current_steer_angle * speed_ratio * 2.8 * dir_mult * drift_mult
		rotate_y(yaw_rate * delta)
		
	# Reconstruct velocity vector
	var new_horiz := -global_transform.basis.z * forward_speed + global_transform.basis.x * lateral_speed
	velocity.x = new_horiz.x
	velocity.z = new_horiz.z
	
	# Audio updates
	_update_audio(delta)

func _handle_parked_physics(delta: float) -> void:
	forward_speed = move_toward(forward_speed, 0.0, 12.0 * delta)
	velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
	current_steer_angle = move_toward(current_steer_angle, 0.0, delta)

func _update_audio(delta: float) -> void:
	if engine_audio and engine_audio.playing:
		var speed_norm: float = clampf(abs(forward_speed) / max_speed, 0.0, 1.0)
		# Variable pitch for engine RPM
		engine_audio.pitch_scale = lerpf(0.85, 2.3, speed_norm)
		
	if screech_audio:
		if is_drifting:
			if not screech_audio.playing:
				screech_audio.play()
		else:
			if screech_audio.playing:
				screech_audio.stop()

func _update_visuals(delta: float) -> void:
	# Rotate front wheels for steering
	if front_left_wheel:
		front_left_wheel.rotation.y = current_steer_angle
	if front_right_wheel:
		front_right_wheel.rotation.y = current_steer_angle
		
	# Wheel spin
	wheel_spin += forward_speed * delta * 5.0
	if front_left_wheel: front_left_wheel.rotation.x = wheel_spin
	if front_right_wheel: front_right_wheel.rotation.x = wheel_spin
	if rear_left_wheel: rear_left_wheel.rotation.x = wheel_spin
	if rear_right_wheel: rear_right_wheel.rotation.x = wheel_spin
	
	# Body tilt / suspension roll
	if body_mesh:
		var target_roll: float = -current_steer_angle * clampf(forward_speed / max_speed, 0.0, 1.0) * 0.15
		var target_pitch: float = clampf(forward_speed * 0.005, -0.08, 0.08)
		body_mesh.rotation.z = lerpf(body_mesh.rotation.z, target_roll, 8.0 * delta)
		body_mesh.rotation.x = lerpf(body_mesh.rotation.x, target_pitch, 8.0 * delta)
		
	# Police siren lights
	if siren_active and siren_lights:
		siren_timer += delta * 12.0
		var is_red: bool = fmod(siren_timer, 2.0) < 1.0
		siren_lights.visible = true
		var light_red: Light3D = siren_lights.get_node_or_null("RedLight")
		var light_blue: Light3D = siren_lights.get_node_or_null("BlueLight")
		if light_red: light_red.visible = is_red
		if light_blue: light_blue.visible = not is_red
	elif siren_lights:
		siren_lights.visible = false
		
	# Chase camera dynamic lag & FOV
	if is_driven and chase_camera and chase_spring_arm:
		var speed_ratio: float = clampf(abs(forward_speed) / max_speed, 0.0, 1.0)
		chase_camera.fov = lerpf(72.0, 92.0, speed_ratio)
		chase_spring_arm.spring_length = lerpf(5.2, 7.0, speed_ratio)

func _check_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		var impact_speed := col.get_angle() # or velocity
		if abs(forward_speed) > 8.0:
			# Play crash sound on hard impact
			var crash_stream := GTAAudio.get_crash_stream()
			var ap := AudioStreamPlayer.new()
			ap.stream = crash_stream
			ap.volume_db = -4.0
			add_child(ap)
			ap.play()
			ap.finished.connect(ap.queue_free)
			
			# Hit pedestrian
			if collider and collider.is_in_group("pedestrians") and collider.has_method("hit_by_vehicle"):
				collider.hit_by_vehicle(global_transform.origin, forward_speed)
				
			forward_speed *= 0.4
			health = maxf(0.0, health - 8.0)
			emit_signal("vehicle_damaged", 8.0)
			break

func _cycle_radio() -> void:
	current_station = (current_station + 1) % station_names.size()
	_play_radio_station()
	emit_signal("radio_station_changed", station_names[current_station])

func _play_radio_station() -> void:
	if not radio_audio:
		return
	if current_station < 3:
		radio_audio.stream = GTAAudio.get_radio_track(current_station)
		radio_audio.play()
	else:
		radio_audio.stop()

func get_speed_kmh() -> float:
	return abs(forward_speed) * 3.6
