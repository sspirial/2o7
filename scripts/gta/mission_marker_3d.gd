class_name MissionMarker3D
extends Area3D

const GTAMaterials = preload("res://scripts/gta/gta_materials.gd")

@export var mission_id: int = 1 # 1 = Matatu Rush, 2 = Checkpoint Blitz, 3 = Evade
@export var marker_color: Color = Color(1.0, 0.85, 0.1)

var rot_icon: float = 0.0
var pulse_time: float = 0.0

@onready var cylinder_mesh: MeshInstance3D = $CylinderMesh
@onready var icon_mesh: MeshInstance3D = $IconMesh

signal mission_marker_triggered(m_id: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_materials()

func _setup_materials() -> void:
	if cylinder_mesh:
		cylinder_mesh.material_override = GTAMaterials.get_glow_material(marker_color, 2.5)
	if icon_mesh:
		icon_mesh.material_override = GTAMaterials.get_glow_material(Color(1, 1, 1), 3.0)

func _process(delta: float) -> void:
	rot_icon += delta * 2.5
	pulse_time += delta * 4.0
	
	if icon_mesh:
		icon_mesh.rotation.y = rot_icon
		icon_mesh.position.y = 2.2 + sin(pulse_time) * 0.25
		
	if cylinder_mesh:
		cylinder_mesh.scale.x = 1.0 + sin(pulse_time) * 0.08
		cylinder_mesh.scale.z = 1.0 + sin(pulse_time) * 0.08

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or (body.is_in_group("vehicles") and body.get("is_driven") == true):
		emit_signal("mission_marker_triggered", mission_id)
