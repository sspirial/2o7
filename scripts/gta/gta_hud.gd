class_name GTAHud
extends CanvasLayer

@onready var cash_label: Label = $TopRight/VBox/CashLabel
@onready var health_bar: ProgressBar = $TopRight/VBox/HealthBar
@onready var armor_bar: ProgressBar = $TopRight/VBox/ArmorBar
@onready var stars_container: HBoxContainer = $TopRight/VBox/StarsContainer
@onready var time_label: Label = $TopRight/VBox/TimeLabel

@onready var radar_control: Control = $BottomLeft/RadarFrame/RadarView
@onready var speedo_container: Control = $BottomRight/SpeedoContainer
@onready var speed_label: Label = $BottomRight/SpeedoContainer/SpeedLabel
@onready var vehicle_name_label: Label = $BottomRight/SpeedoContainer/VehicleNameLabel

@onready var radio_banner: PanelContainer = $CenterTop/RadioBanner
@onready var radio_label: Label = $CenterTop/RadioBanner/RadioLabel

@onready var mission_banner: PanelContainer = $CenterTop/MissionBanner
@onready var mission_title_label: Label = $CenterTop/MissionBanner/VBox/TitleLabel
@onready var mission_sub_label: Label = $CenterTop/MissionBanner/VBox/SubLabel

@onready var prompt_label: Label = $CenterBottom/PromptLabel

var player_ref: Node = null
var current_vehicle_ref: Node = null
var current_cash: int = 1500
var wanted_stars: int = 0
var star_flash_timer: float = 0.0

var radio_banner_timer: float = 0.0
var mission_banner_timer: float = 0.0
var objective_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	_update_cash_display()
	_update_stars_display()
	if radio_banner: radio_banner.visible = false
	if mission_banner: mission_banner.visible = false
	if speedo_container: speedo_container.visible = false
	if radar_control:
		radar_control.draw.connect(func(): draw_radar(radar_control))

func set_player(player: Node) -> void:
	player_ref = player
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)

func set_current_vehicle(veh: Node) -> void:
	current_vehicle_ref = veh
	if speedo_container:
		speedo_container.visible = (veh != null)
	if veh != null and vehicle_name_label:
		vehicle_name_label.text = veh.get("vehicle_name") if veh.get("vehicle_name") else "Vehicle"

func add_cash(amount: int) -> void:
	current_cash += amount
	_update_cash_display()

func set_wanted_level(stars: int) -> void:
	wanted_stars = clamp(stars, 0, 5)
	_update_stars_display()

func _update_cash_display() -> void:
	if cash_label:
		cash_label.text = "$%07d" % current_cash

func _update_stars_display() -> void:
	if not stars_container:
		return
	var children := stars_container.get_children()
	for i in range(children.size()):
		var star_label: Label = children[i] as Label
		if star_label:
			if i < wanted_stars:
				star_label.modulate = Color(1.0, 0.85, 0.1) # Bright Gold
			else:
				star_label.modulate = Color(0.25, 0.25, 0.25, 0.6) # Dark grey

func _on_health_changed(curr: float, max_v: float) -> void:
	if health_bar:
		health_bar.value = (curr / max_v) * 100.0

func show_radio_station(st_name: String) -> void:
	if radio_banner and radio_label:
		radio_label.text = "📻  " + st_name
		radio_banner.visible = true
		radio_banner_timer = 3.0

func show_mission_passed(reward: int, title: String) -> void:
	add_cash(reward)
	if mission_banner and mission_title_label and mission_sub_label:
		mission_title_label.text = "MISSION PASSED!"
		mission_title_label.modulate = Color(0.2, 0.9, 0.2)
		mission_sub_label.text = "%s  |  +$%d" % [title, reward]
		mission_banner.visible = true
		mission_banner_timer = 5.0

func show_mission_failed(reason: String) -> void:
	if mission_banner and mission_title_label and mission_sub_label:
		mission_title_label.text = "MISSION FAILED"
		mission_title_label.modulate = Color(0.9, 0.2, 0.2)
		mission_sub_label.text = reason
		mission_banner.visible = true
		mission_banner_timer = 4.0

func show_mission_active(title: String, instruction: String, time_rem: float) -> void:
	if mission_banner and mission_title_label and mission_sub_label:
		mission_title_label.text = title
		mission_title_label.modulate = Color(1.0, 0.85, 0.1)
		mission_sub_label.text = "%s  [%d s]" % [instruction, int(time_rem)]
		mission_banner.visible = true
		mission_banner_timer = 0.5

func _process(delta: float) -> void:
	# Radio banner timer
	if radio_banner_timer > 0.0:
		radio_banner_timer -= delta
		if radio_banner_timer <= 0.0 and radio_banner:
			radio_banner.visible = false
			
	# Mission banner timer
	if mission_banner_timer > 0.0:
		mission_banner_timer -= delta
		if mission_banner_timer <= 0.0 and mission_banner:
			mission_banner.visible = false
			
	# Wanted star flashing when wanted
	if wanted_stars > 0 and stars_container:
		star_flash_timer += delta * 6.0
		var flash_col := Color(1.0, 0.85, 0.1) if fmod(star_flash_timer, 2.0) < 1.0 else Color(0.9, 0.2, 0.2)
		var children := stars_container.get_children()
		for i in range(wanted_stars):
			if i < children.size():
				(children[i] as CanvasItem).modulate = flash_col
				
	# Speedometer update
	if current_vehicle_ref and speed_label and speedo_container.visible:
		var kmh: float = current_vehicle_ref.get_speed_kmh() if current_vehicle_ref.has_method("get_speed_kmh") else 0.0
		speed_label.text = "%03d KM/H" % int(kmh)
		
	# Interaction prompt update
	if prompt_label:
		if player_ref and not current_vehicle_ref:
			var near_veh: Node = player_ref.get("nearby_vehicle")
			if near_veh:
				prompt_label.text = "Press [F] or [E] to Enter Vehicle"
				prompt_label.visible = true
			else:
				prompt_label.text = "[WASD] Move   [SHIFT] Sprint   [SPACE] Jump   [M/ESC] Mouse"
				prompt_label.visible = true
		elif current_vehicle_ref:
			prompt_label.text = "[WASD] Drive   [SPACE] Drift   [H] Horn   [R] Radio   [F/E] Exit"
			prompt_label.visible = true
			
	# Queue redraw for Minimap / Radar
	if radar_control:
		radar_control.queue_redraw()

func draw_radar(cv: Control) -> void:
	if not player_ref:
		return
		
	var center := cv.size * 0.5
	var radius := minf(center.x, center.y) - 4.0
	
	# Radar background disc
	cv.draw_circle(center, radius, Color(0.08, 0.1, 0.14, 0.85))
	cv.draw_arc(center, radius, 0.0, TAU, 32, Color(0.3, 0.8, 0.4, 0.8), 2.0)
	
	var p_pos: Vector3 = player_ref.global_position if not current_vehicle_ref else current_vehicle_ref.global_position
	var p_rot_y: float = player_ref.rotation.y if not current_vehicle_ref else current_vehicle_ref.rotation.y
	
	# Scale: 1 radar pixel = 1.2 world meters
	var world_scale: float = 0.85
	
	# Draw North indicator on radar rim
	var north_angle := -p_rot_y - PI * 0.5
	var north_pos := center + Vector2(cos(north_angle), sin(north_angle)) * (radius - 8.0)
	cv.draw_string(ThemeDB.fallback_font, north_pos, "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(1, 0.2, 0.2))
	
	# Draw road grid relative to player
	var roads_z: Array[float] = [-60.0, 0.0, 60.0]
	for rz in roads_z:
		var rel_z := rz - p_pos.z
		var screen_pt := center + Vector2(0, rel_z * world_scale).rotated(-p_rot_y)
		if screen_pt.distance_to(center) < radius - 6.0:
			var road_dir := Vector2(1, 0).rotated(-p_rot_y) * (radius - 8.0)
			cv.draw_line(screen_pt - road_dir, screen_pt + road_dir, Color(0.35, 0.38, 0.42, 0.6), 5.0)
			
	var roads_x: Array[float] = [-60.0, 0.0, 60.0]
	for rx in roads_x:
		var rel_x := rx - p_pos.x
		var screen_pt := center + Vector2(rel_x * world_scale, 0).rotated(-p_rot_y)
		if screen_pt.distance_to(center) < radius - 6.0:
			var road_dir := Vector2(0, 1).rotated(-p_rot_y) * (radius - 8.0)
			cv.draw_line(screen_pt - road_dir, screen_pt + road_dir, Color(0.35, 0.38, 0.42, 0.6), 5.0)
			
	# Draw vehicles on radar
	var vehs := cv.get_tree().get_nodes_in_group("vehicles")
	for v in vehs:
		if v is Node3D and v != current_vehicle_ref:
			var offset: Vector3 = (v as Node3D).global_position - p_pos
			var radar_offset := Vector2(offset.x, offset.z).rotated(-p_rot_y) * world_scale
			if radar_offset.length() < radius - 8.0:
				cv.draw_rect(Rect2(center + radar_offset - Vector2(3, 3), Vector2(6, 6)), Color(0.2, 0.6, 1.0))
				
	# Draw objective if exists
	if objective_pos != Vector3.ZERO:
		var obj_offset := Vector2(objective_pos.x - p_pos.x, objective_pos.z - p_pos.z).rotated(-p_rot_y) * world_scale
		if obj_offset.length() > radius - 10.0:
			obj_offset = obj_offset.normalized() * (radius - 10.0)
		cv.draw_rect(Rect2(center + obj_offset - Vector2(4, 4), Vector2(8, 8)), Color(1.0, 0.85, 0.1))
		
	# Draw player center triangle arrow
	var arrow_pts: PackedVector2Array = [
		center + Vector2(0, -7),
		center + Vector2(-5, 6),
		center + Vector2(0, 3),
		center + Vector2(5, 6)
	]
	cv.draw_colored_polygon(arrow_pts, Color(0.1, 0.95, 0.3))
