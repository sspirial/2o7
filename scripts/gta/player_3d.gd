class_name Player3D
extends CharacterBody3D

const GTAAudio = preload("res://scripts/gta/gta_audio.gd")
const GTAMaterials = preload("res://scripts/gta/gta_materials.gd")

signal entered_vehicle(vehicle: Node)
signal exited_vehicle()
signal health_changed(current: float, max_val: float)
signal died()

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 9.5
@export var jump_velocity: float = 7.0
@export var mouse_sensitivity: float = 0.003
@export var max_health: float = 100.0

var current_health: float = 100.0
var is_in_vehicle: bool = false
var current_vehicle: Node = null
var nearby_vehicle: Node = null

var camera_pitch: float = -0.2
var camera_yaw: float = 0.0
var mouse_captured: bool = false

var anim_phase: float = 0.0
var step_timer: float = 0.0

@onready var visuals: Node3D = $Visuals
@onready var camera_rig: Node3D = $CameraRig
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D
@onready var footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var interaction_area: Area3D = $InteractionArea

# Procedural limb references
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso: Node3D
var head: Node3D

func _ready() -> void:
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	
	_setup_limbs()
	_setup_audio()
	
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_body_entered)
		interaction_area.body_exited.connect(_on_interaction_body_exited)
		
	# Initial camera rotation
	_update_camera_rotation()

func _setup_audio() -> void:
	if not footstep_player:
		footstep_player = AudioStreamPlayer.new()
		footstep_player.name = "FootstepPlayer"
		add_child(footstep_player)
	footstep_player.stream = GTAAudio.get_footstep_stream()
	footstep_player.volume_db = -6.0

func _setup_limbs() -> void:
	if visuals:
		left_arm = visuals.get_node_or_null("Torso/LeftArmPivot")
		right_arm = visuals.get_node_or_null("Torso/RightArmPivot")
		left_leg = visuals.get_node_or_null("LeftLegPivot")
		right_leg = visuals.get_node_or_null("RightLegPivot")
		torso = visuals.get_node_or_null("Torso")
		head = visuals.get_node_or_null("Torso/Head")

func set_mouse_captured(captured: bool) -> void:
	mouse_captured = captured
	if captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if is_in_vehicle:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		set_mouse_captured(true)
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		set_mouse_captured(false)
		
	if mouse_captured and event is InputEventMouseMotion:
		camera_yaw -= event.relative.x * mouse_sensitivity
		camera_pitch = clampf(camera_pitch - event.relative.y * mouse_sensitivity, -1.3, 0.8)
		_update_camera_rotation()
		
	if Input.is_action_just_pressed("interact") or (event is InputEventKey and event.pressed and (event.keycode == KEY_F or event.keycode == KEY_E)):
		if nearby_vehicle and not is_in_vehicle:
			enter_vehicle(nearby_vehicle)

func _update_camera_rotation() -> void:
	if camera_rig:
		camera_rig.rotation.y = camera_yaw
	if spring_arm:
		spring_arm.rotation.x = camera_pitch

func _physics_process(delta: float) -> void:
	if is_in_vehicle:
		return
		
	# Gravity
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	elif velocity.y < 0.0:
		velocity.y = -0.5
		
	# Jumping
	var jump_pressed: bool = Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_SPACE)
	if is_on_floor() and jump_pressed:
		velocity.y = jump_velocity
		
	# Movement input
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
		
	input_dir = input_dir.normalized()
	
	# Sprint check
	var is_sprinting: bool = (Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)) and input_dir.length() > 0.1
	var current_speed: float = sprint_speed if is_sprinting else walk_speed
	
	# Relative to camera orientation
	var cam_basis := Basis(Vector3.UP, camera_yaw)
	var move_vec := (cam_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	
	if move_vec.length() > 0.1:
		velocity.x = move_vec.x * current_speed
		velocity.z = move_vec.z * current_speed
		# Rotate character visuals towards movement direction
		var target_angle: float = atan2(-move_vec.x, -move_vec.z)
		if visuals:
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 14.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed * 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, current_speed * 12.0 * delta)
		
	move_and_slide()
	
	# Procedural limb animation
	_animate_character(delta, Vector2(velocity.x, velocity.z).length(), is_sprinting)

func _animate_character(delta: float, horiz_speed: float, sprinting: bool) -> void:
	if not is_on_floor():
		# In air / jump pose
		if left_leg: left_leg.rotation.x = lerpf(left_leg.rotation.x, -0.6, 10.0 * delta)
		if right_leg: right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.3, 10.0 * delta)
		if left_arm: left_arm.rotation.x = lerpf(left_arm.rotation.x, 0.8, 10.0 * delta)
		if right_arm: right_arm.rotation.x = lerpf(right_arm.rotation.x, 0.8, 10.0 * delta)
		if torso: torso.position.y = lerpf(torso.position.y, 0.95, 10.0 * delta)
		return
		
	if horiz_speed > 0.4:
		var freq: float = 12.0 if sprinting else 8.5
		anim_phase += delta * freq
		var swing: float = sin(anim_phase)
		var swing_amp: float = 0.9 if sprinting else 0.55
		
		# Legs
		if left_leg: left_leg.rotation.x = swing * swing_amp
		if right_leg: right_leg.rotation.x = -swing * swing_amp
		# Arms counter-swing
		if left_arm: left_arm.rotation.x = -swing * swing_amp * 0.9
		if right_arm: right_arm.rotation.x = swing * swing_amp * 0.9
		# Torso bob
		if torso:
			torso.position.y = 0.9 + abs(sin(anim_phase * 2.0)) * 0.06
			
		# Footsteps
		step_timer += delta * freq
		if step_timer >= PI:
			step_timer = 0.0
			if footstep_player and not footstep_player.playing:
				footstep_player.pitch_scale = randf_range(0.9, 1.15)
				footstep_player.play()
	else:
		# Idle breathing
		anim_phase += delta * 2.5
		if left_leg: left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.0, 10.0 * delta)
		if right_leg: right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.0, 10.0 * delta)
		if left_arm: left_arm.rotation.x = lerpf(left_arm.rotation.x, sin(anim_phase) * 0.05, 10.0 * delta)
		if right_arm: right_arm.rotation.x = lerpf(right_arm.rotation.x, -sin(anim_phase) * 0.05, 10.0 * delta)
		if torso: torso.position.y = lerpf(torso.position.y, 0.9 + sin(anim_phase) * 0.02, 10.0 * delta)

func enter_vehicle(vehicle: Node) -> void:
	if not vehicle or not vehicle.has_method("mount_driver"):
		return
	is_in_vehicle = true
	current_vehicle = vehicle
	visible = false
	collision_layer = 0
	collision_mask = 0
	
	if camera:
		camera.current = false
		
	vehicle.mount_driver(self)
	emit_signal("entered_vehicle", vehicle)

func exit_vehicle() -> void:
	if not current_vehicle:
		return
		
	var exit_pos: Vector3 = current_vehicle.get_exit_position()
	global_position = exit_pos
	visible = true
	collision_layer = 2
	collision_mask = 1
	velocity = Vector3.ZERO
	
	if camera:
		camera.current = true
		
	var veh := current_vehicle
	current_vehicle = null
	is_in_vehicle = false
	
	veh.unmount_driver()
	emit_signal("exited_vehicle")

func take_damage(amount: float) -> void:
	current_health = maxf(0.0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	if current_health <= 0.0:
		emit_signal("died")

func _on_interaction_body_entered(body: Node) -> void:
	if body.is_in_group("vehicles"):
		nearby_vehicle = body

func _on_interaction_body_exited(body: Node) -> void:
	if body == nearby_vehicle:
		nearby_vehicle = null
