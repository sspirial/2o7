class_name Pedestrian3D
extends CharacterBody3D

const GTAAudio = preload("res://scripts/gta/gta_audio.gd")
const GTAMaterials = preload("res://scripts/gta/gta_materials.gd")

@export var walk_speed: float = 2.2
@export var run_speed: float = 5.5

enum PedState {
	WALKING,
	PANIC,
	KNOCKED_DOWN,
	IDLE
}

var state: PedState = PedState.WALKING
var patrol_points: Array[Vector3] = []
var target_index: int = 0
var anim_phase: float = 0.0
var panic_timer: float = 0.0
var knockdown_timer: float = 0.0

@onready var visuals: Node3D = $Visuals
@onready var left_leg: Node3D = $Visuals/LeftLegPivot
@onready var right_leg: Node3D = $Visuals/RightLegPivot
@onready var left_arm: Node3D = $Visuals/Torso/LeftArmPivot
@onready var right_arm: Node3D = $Visuals/Torso/RightArmPivot
@onready var torso: Node3D = $Visuals/Torso

signal pedestrian_hit(ped: Node)

func _ready() -> void:
	add_to_group("pedestrians")
	_randomize_appearance()

func _randomize_appearance() -> void:
	if visuals:
		# Random shirt color
		var colors: Array[Color] = [
			Color(0.2, 0.6, 0.8),
			Color(0.9, 0.4, 0.2),
			Color(0.2, 0.7, 0.3),
			Color(0.8, 0.2, 0.5),
			Color(0.9, 0.8, 0.2)
		]
		var c: Color = colors[randi() % colors.size()]
		var torso_mesh: MeshInstance3D = visuals.get_node_or_null("Torso/TorsoMesh")
		if torso_mesh:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = c
			torso_mesh.material_override = mat

func set_patrol_path(points: Array) -> void:
	patrol_points.clear()
	for pt in points:
		patrol_points.append(pt as Vector3)
	target_index = 0

func hit_by_vehicle(vehicle_pos: Vector3, speed: float) -> void:
	if state == PedState.KNOCKED_DOWN:
		return
		
	state = PedState.KNOCKED_DOWN
	knockdown_timer = 3.5
	
	# Launch vector away from impact
	var launch_dir := (global_position - vehicle_pos).normalized()
	launch_dir.y = 0.6
	velocity = launch_dir * minf(speed * 0.8, 16.0)
	
	emit_signal("pedestrian_hit", self)

func panic_from(danger_pos: Vector3) -> void:
	if state == PedState.KNOCKED_DOWN:
		return
	state = PedState.PANIC
	panic_timer = 4.0
	
	# Run away from danger
	var flee_dir := (global_position - danger_pos).normalized()
	flee_dir.y = 0.0
	if flee_dir.length() > 0.1:
		var target_angle: float = atan2(-flee_dir.x, -flee_dir.z)
		rotation.y = target_angle

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	elif velocity.y < 0.0:
		velocity.y = -0.5
		
	match state:
		PedState.WALKING:
			_process_walking(delta)
		PedState.PANIC:
			_process_panic(delta)
		PedState.KNOCKED_DOWN:
			_process_knockdown(delta)
		PedState.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			
	move_and_slide()
	_animate(delta)

func _process_walking(delta: float) -> void:
	if patrol_points.is_empty():
		return
		
	var target := patrol_points[target_index]
	var diff := target - global_position
	diff.y = 0.0
	
	if diff.length() < 1.5:
		target_index = (target_index + 1) % patrol_points.size()
		return
		
	var dir := diff.normalized()
	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed
	
	var target_angle: float = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 6.0 * delta)
	
	# Check for close speeding cars
	_check_traffic_proximity()

func _process_panic(delta: float) -> void:
	panic_timer -= delta
	if panic_timer <= 0.0:
		state = PedState.WALKING
		return
		
	var forward := -global_transform.basis.z
	velocity.x = forward.x * run_speed
	velocity.z = forward.z * run_speed

func _process_knockdown(delta: float) -> void:
	knockdown_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
	
	# Tumble on ground
	if visuals:
		visuals.rotation.x = lerpf(visuals.rotation.x, -PI * 0.45, 10.0 * delta)
		
	if knockdown_timer <= 0.0:
		state = PedState.WALKING
		if visuals:
			visuals.rotation.x = 0.0

func _check_traffic_proximity() -> void:
	var vehicles := get_tree().get_nodes_in_group("vehicles")
	for v in vehicles:
		if v is CharacterBody3D and v != self:
			var d := global_position.distance_to(v.global_position)
			if d < 6.5 and v.velocity.length() > 6.0:
				panic_from(v.global_position)
				break

func _animate(delta: float) -> void:
	if state == PedState.KNOCKED_DOWN:
		return
		
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if horiz_speed > 0.2:
		var freq := 8.0 if state == PedState.WALKING else 14.0
		anim_phase += delta * freq
		var swing := sin(anim_phase)
		var amp := 0.5 if state == PedState.WALKING else 0.8
		
		if left_leg: left_leg.rotation.x = swing * amp
		if right_leg: right_leg.rotation.x = -swing * amp
		if left_arm: left_arm.rotation.x = -swing * amp * 0.8
		if right_arm: right_arm.rotation.x = swing * amp * 0.8
	else:
		if left_leg: left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.0, 10.0 * delta)
		if right_leg: right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.0, 10.0 * delta)
		if left_arm: left_arm.rotation.x = lerpf(left_arm.rotation.x, 0.0, 10.0 * delta)
		if right_arm: right_arm.rotation.x = lerpf(right_arm.rotation.x, 0.0, 10.0 * delta)
