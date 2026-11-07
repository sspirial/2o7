class_name CityBuilder
extends Node3D

const GTAMaterials = preload("res://scripts/gta/gta_materials.gd")

func build_city() -> void:
	_create_ground_and_roads()
	_create_buildings()
	_create_props_and_lighting()
	_create_stunt_ramps()

func _create_ground_and_roads() -> void:
	# Main ground plane (grass/base)
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(300, 300)
	var ground_inst := MeshInstance3D.new()
	ground_inst.name = "GroundBase"
	ground_inst.mesh = ground_mesh
	ground_inst.material_override = GTAMaterials.get_grass_material()
	add_child(ground_inst)
	
	# Static collision for ground
	var static_body := StaticBody3D.new()
	static_body.collision_layer = 1
	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(300, 1.0, 300)
	col_shape.shape = box_shape
	col_shape.position = Vector3(0, -0.5, 0)
	static_body.add_child(col_shape)
	ground_inst.add_child(static_body)
	
	# East-West Main Avenues (z = -60, z = 0, z = 60)
	var z_roads: Array[float] = [-60.0, 0.0, 60.0]
	for rz in z_roads:
		_create_road_segment(Vector3(0, 0.02, rz), Vector2(240, 16), false)
		# Sidewalks North and South of this road
		_create_sidewalk_strip(Vector3(0, 0.12, rz + 10.0), Vector2(240, 4.0))
		_create_sidewalk_strip(Vector3(0, 0.12, rz - 10.0), Vector2(240, 4.0))
		
	# North-South Cross Avenues (x = -60, x = 0, x = 60)
	var x_roads: Array[float] = [-60.0, 0.0, 60.0]
	for rx in x_roads:
		_create_road_segment(Vector3(rx, 0.03, 0), Vector2(16, 240), true)
		# Sidewalks East and West
		_create_sidewalk_strip(Vector3(rx + 10.0, 0.12, 0), Vector2(4.0, 240))
		_create_sidewalk_strip(Vector3(rx - 10.0, 0.12, 0), Vector2(4.0, 240))

func _create_road_segment(pos: Vector3, size: Vector2, rotated: bool) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = GTAMaterials.get_road_material()
	if rotated:
		inst.rotation.y = PI * 0.5
	add_child(inst)

func _create_sidewalk_strip(pos: Vector3, size: Vector2) -> void:
	var inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.24, size.y)
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = GTAMaterials.get_sidewalk_material()
	
	var static_body := StaticBody3D.new()
	static_body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	col.shape = shape
	static_body.add_child(col)
	inst.add_child(static_body)
	
	add_child(inst)

func _create_buildings() -> void:
	# Blocks are situated between roads:
	# Block quadrants: (-120..-70, -120..-70), (-70..-10, -70..-10), etc.
	var block_centers: Array[Vector2] = [
		Vector2(-90, -90), Vector2(-30, -90), Vector2(30, -90), Vector2(90, -90),
		Vector2(-90, -30), Vector2(-30, -30), Vector2(30, -30), Vector2(90, -30),
		Vector2(-90,  30), Vector2(-30,  30), Vector2(30,  30), Vector2(90,  30),
		Vector2(-90,  90), Vector2(-30,  90), Vector2(30,  90), Vector2(90,  90)
	]
	
	var rng := RandomNumberGenerator.new()
	rng.seed = 2007 # Fixed seed for consistent, beautiful cityscape
	
	for i in range(block_centers.size()):
		var center := block_centers[i]
		
		# Center block (30, -30) is the Matatu Stage Terminus plaza!
		if i == 6:
			_create_stage_terminus(Vector3(center.x, 0, center.y))
			continue
			
		# Pick building style
		var height: float = rng.randf_range(16.0, 42.0)
		var bldg_type: int = rng.randi() % 4
		
		# Main tower in block
		_create_building(Vector3(center.x, height * 0.5, center.y), Vector3(32, height, 32), bldg_type)
		
		# Rooftop billboard
		if height > 22.0:
			_create_billboard(Vector3(center.x, height + 2.5, center.y), rng.randi() % 3)
			
		# Corner roadside kiosks in front of buildings
		var kiosk_pos := Vector3(center.x + 18.0, 1.5, center.y + 18.0)
		_create_kiosk(kiosk_pos)

func _create_building(pos: Vector3, size: Vector3, type_idx: int) -> void:
	var inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = GTAMaterials.get_building_material(type_idx)
	
	var static_body := StaticBody3D.new()
	static_body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	static_body.add_child(col)
	inst.add_child(static_body)
	
	add_child(inst)

func _create_billboard(pos: Vector3, style: int) -> void:
	var inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(14.0, 4.0, 0.8)
	inst.mesh = mesh
	inst.position = pos
	
	var mat := StandardMaterial3D.new()
	match style:
		0:
			mat.albedo_color = Color(0.1, 0.7, 0.2) # Safaricom green
		1:
			mat.albedo_color = Color(0.9, 0.75, 0.1) # Tusker yellow
		_:
			mat.albedo_color = Color(0.85, 0.15, 0.2) # Stage 7 red
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.8
	inst.material_override = mat
	add_child(inst)

func _create_kiosk(pos: Vector3) -> void:
	var inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(5.0, 3.0, 4.0)
	inst.mesh = mesh
	inst.position = pos
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.35, 0.2) # Wood planks
	inst.material_override = mat
	
	# Slanted corrugated blue iron roof
	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(5.6, 0.2, 4.6)
	roof.mesh = roof_mesh
	roof.position = Vector3(0, 1.6, 0)
	roof.rotation.x = 0.12
	roof.material_override = GTAMaterials.get_kiosk_roof_material()
	inst.add_child(roof)
	
	var static_body := StaticBody3D.new()
	static_body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	col.shape = shape
	static_body.add_child(col)
	inst.add_child(static_body)
	
	add_child(inst)

func _create_stage_terminus(pos: Vector3) -> void:
	# Wide bus parking bay
	var bay := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(40, 0.1, 40)
	bay.mesh = mesh
	bay.position = pos
	bay.material_override = GTAMaterials.get_sidewalk_material()
	add_child(bay)
	
	# Terminus Shelter Roof
	var shelter := MeshInstance3D.new()
	var smesh := BoxMesh.new()
	smesh.size = Vector3(25, 0.4, 12)
	shelter.mesh = smesh
	shelter.position = pos + Vector3(0, 4.5, 0)
	shelter.material_override = GTAMaterials.get_kiosk_roof_material()
	add_child(shelter)
	
	# Signboard: "STAGE 7 TERMINUS - NAIROBI"
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(18, 2.0, 0.5)
	var sign_inst := MeshInstance3D.new()
	sign_inst.mesh = sign_mesh
	sign_inst.position = pos + Vector3(0, 5.8, 0)
	sign_inst.material_override = GTAMaterials.get_glow_material(Color(1.0, 0.85, 0.1), 2.5)
	add_child(sign_inst)

func _create_props_and_lighting() -> void:
	# Street lights along main avenues
	var light_z_coords: Array[float] = [-60.0, 0.0, 60.0]
	for z in light_z_coords:
		for x in range(-100, 101, 35):
			_create_street_lamp(Vector3(float(x), 0, z + 8.5))
			_create_street_lamp(Vector3(float(x), 0, z - 8.5))
			# Palm trees along sidewalk
			if (x % 70) == 0:
				_create_palm_tree(Vector3(float(x) + 12.0, 0, z + 9.0))

func _create_street_lamp(pos: Vector3) -> void:
	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.08
	post_mesh.bottom_radius = 0.12
	post_mesh.height = 6.0
	post.mesh = post_mesh
	post.position = pos + Vector3(0, 3.0, 0)
	
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.2, 0.22, 0.25)
	post_mat.metallic = 0.8
	post.material_override = post_mat
	
	# Lamp fixture
	var lamp_head := MeshInstance3D.new()
	var lamp_mesh := BoxMesh.new()
	lamp_mesh.size = Vector3(0.4, 0.2, 0.8)
	lamp_head.mesh = lamp_mesh
	lamp_head.position = Vector3(0, 3.0, 0.3)
	lamp_head.material_override = GTAMaterials.get_glow_material(Color(1.0, 0.92, 0.7), 3.0)
	post.add_child(lamp_head)
	
	# Real 3D light pool!
	var omni := OmniLight3D.new()
	omni.position = Vector3(0, 2.7, 0.3)
	omni.light_color = Color(1.0, 0.9, 0.72)
	omni.light_energy = 2.2
	omni.omni_range = 14.0
	omni.omni_attenuation = 1.2
	post.add_child(omni)
	
	add_child(post)

func _create_palm_tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var t_mesh := CylinderMesh.new()
	t_mesh.top_radius = 0.2
	t_mesh.bottom_radius = 0.35
	t_mesh.height = 6.5
	trunk.mesh = t_mesh
	trunk.position = pos + Vector3(0, 3.25, 0)
	
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.45, 0.3, 0.18)
	trunk.material_override = trunk_mat
	
	# Palm crown fronds
	for i in range(5):
		var frond := MeshInstance3D.new()
		var f_mesh := BoxMesh.new()
		f_mesh.size = Vector3(0.6, 0.1, 3.5)
		frond.mesh = f_mesh
		frond.position = Vector3(0, 3.2, 0)
		frond.rotation.y = float(i) * (TAU / 5.0)
		frond.rotation.x = 0.4
		
		var leaf_mat := StandardMaterial3D.new()
		leaf_mat.albedo_color = Color(0.18, 0.62, 0.22)
		frond.material_override = leaf_mat
		trunk.add_child(frond)
		
	add_child(trunk)

func _create_stunt_ramps() -> void:
	# Stunt ramps across the city for high-speed car jumps!
	var ramp_positions: Array[Vector3] = [
		Vector3(-45.0, 0, 0),
		Vector3(45.0, 0, 0),
		Vector3(0, 0, -45.0)
	]
	
	for rpos in ramp_positions:
		var ramp := MeshInstance3D.new()
		var r_mesh := BoxMesh.new()
		r_mesh.size = Vector3(6.0, 2.5, 8.0)
		ramp.mesh = r_mesh
		ramp.position = rpos + Vector3(0, 1.0, 0)
		ramp.rotation.x = -0.26 # Ramp slope
		
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.7, 0.1) # Warning yellow
		ramp.material_override = mat
		
		var static_body := StaticBody3D.new()
		static_body.collision_layer = 1
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = r_mesh.size
		col.shape = shape
		static_body.add_child(col)
		ramp.add_child(static_body)
		
		add_child(ramp)
