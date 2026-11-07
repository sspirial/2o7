class_name GTAMaterials
extends RefCounted

static var _cache: Dictionary = {}

static func get_road_material() -> StandardMaterial3D:
	if _cache.has("road"):
		return _cache["road"]
	
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var col_asphalt := Color(0.14, 0.14, 0.16)
	var col_yellow := Color(0.95, 0.78, 0.12)
	var col_white := Color(0.92, 0.92, 0.92)
	var col_curb := Color(0.65, 0.65, 0.65)
	
	for y in range(256):
		for x in range(256):
			var c := col_asphalt
			# Subtle asphalt noise grain
			var grain: float = (randf() - 0.5) * 0.04
			c = Color(c.r + grain, c.g + grain, c.b + grain)
			
			# Curbs at edges (x < 12 or x > 243)
			if x < 12 or x > 243:
				c = col_curb
			# Yellow double center line (x between 124 and 132)
			elif (x >= 123 and x <= 126) or (x >= 129 and x <= 132):
				c = col_yellow
			# White dashed lanes (at x = 68 and x = 188, dashed vertically every 64 pixels)
			elif (abs(x - 68) <= 2 or abs(x - 188) <= 2) and (y % 64 < 36):
				c = col_white
				
			img.set_pixel(x, y, c)
			
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.uv1_scale = Vector3(1, 4, 1)
	mat.roughness = 0.85
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_cache["road"] = mat
	return mat

static func get_crosswalk_material() -> StandardMaterial3D:
	if _cache.has("crosswalk"):
		return _cache["crosswalk"]
		
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var col_asphalt := Color(0.14, 0.14, 0.16)
	var col_white := Color(0.92, 0.92, 0.92)
	
	for y in range(128):
		for x in range(128):
			var is_stripe := (y % 32) < 18
			img.set_pixel(x, y, col_white if is_stripe else col_asphalt)
			
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.85
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_cache["crosswalk"] = mat
	return mat

static func get_sidewalk_material() -> StandardMaterial3D:
	if _cache.has("sidewalk"):
		return _cache["sidewalk"]
		
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var col_pave := Color(0.68, 0.67, 0.64)
	var col_grout := Color(0.42, 0.41, 0.39)
	
	for y in range(64):
		for x in range(64):
			if x == 0 or y == 0 or x == 32 or y == 32:
				img.set_pixel(x, y, col_grout)
			else:
				var grain: float = (randf() - 0.5) * 0.05
				img.set_pixel(x, y, Color(col_pave.r + grain, col_pave.g + grain, col_pave.b + grain))
				
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.uv1_scale = Vector3(4, 4, 4)
	mat.roughness = 0.9
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_cache["sidewalk"] = mat
	return mat

static func get_building_material(building_type: int = 0) -> StandardMaterial3D:
	var key := "building_%d" % building_type
	if _cache.has(key):
		return _cache[key]
		
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var base_col: Color
	match building_type:
		0: base_col = Color(0.35, 0.40, 0.48) # Steel blue office
		1: base_col = Color(0.72, 0.45, 0.32) # Nairobi terracotta brick
		2: base_col = Color(0.85, 0.82, 0.75) # Warm cream commercial
		_: base_col = Color(0.28, 0.30, 0.34) # Modern charcoal
		
	for y in range(128):
		var floor_idx: int = y / 24
		var is_floor_band: bool = (y % 24) < 4
		for x in range(128):
			var is_col_band: bool = (x % 24) < 4
			if is_floor_band or is_col_band:
				img.set_pixel(x, y, base_col * 0.8)
			else:
				# Window pane
				var is_lit: bool = ((x / 24) * 7 + floor_idx * 13) % 5 > 1
				if is_lit:
					var warm_glow: Color = Color(1.0, 0.92, 0.65) if (floor_idx % 2 == 0) else Color(0.65, 0.85, 1.0)
					img.set_pixel(x, y, warm_glow)
				else:
					img.set_pixel(x, y, Color(0.08, 0.10, 0.14))
					
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.uv1_scale = Vector3(1, 2, 1)
	mat.roughness = 0.4
	mat.metallic = 0.2
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_cache[key] = mat
	return mat

static func get_matatu_material() -> StandardMaterial3D:
	if _cache.has("matatu"):
		return _cache["matatu"]
		
	# Vibrant Nairobi Matatu graffiti paintwork!
	var img := Image.create(256, 128, false, Image.FORMAT_RGBA8)
	for y in range(128):
		for x in range(256):
			var c: Color
			if y < 35:
				c = Color(0.95, 0.15, 0.25) # Bright hot red roof/top
			elif y < 55:
				c = Color(1.0, 0.85, 0.1) # Golden yellow stripe
			elif y < 85:
				# Electric cyan with diagonal graffiti stripes
				var diag := (x + y * 2) % 30 < 12
				c = Color(0.05, 0.75, 0.95) if diag else Color(0.98, 0.45, 0.05)
			else:
				c = Color(0.12, 0.12, 0.15) # Black skirts/trim
			img.set_pixel(x, y, c)
			
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.25
	mat.metallic = 0.45
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_cache["matatu"] = mat
	return mat

static func get_taxi_material() -> StandardMaterial3D:
	if _cache.has("taxi"):
		return _cache["taxi"]
		
	var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	var col_yellow := Color(0.96, 0.82, 0.12)
	var col_black := Color(0.1, 0.1, 0.1)
	var col_white := Color(0.95, 0.95, 0.95)
	
	for y in range(64):
		for x in range(128):
			if y >= 26 and y <= 38:
				# Checkerboard stripe
				var chk := ((x / 12) + (y / 6)) % 2 == 0
				img.set_pixel(x, y, col_black if chk else col_white)
			else:
				img.set_pixel(x, y, col_yellow)
				
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.3
	mat.metallic = 0.35
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_cache["taxi"] = mat
	return mat

static func get_police_material() -> StandardMaterial3D:
	if _cache.has("police"):
		return _cache["police"]
		
	var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	var col_white := Color(0.94, 0.94, 0.96)
	var col_black := Color(0.08, 0.08, 0.1)
	var col_blue := Color(0.1, 0.3, 0.85)
	
	for y in range(64):
		for x in range(128):
			if y >= 24 and y <= 36:
				img.set_pixel(x, y, col_blue)
			elif y < 20 or y > 44:
				img.set_pixel(x, y, col_black)
			else:
				img.set_pixel(x, y, col_white)
				
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.25
	mat.metallic = 0.5
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_cache["police"] = mat
	return mat

static func get_muscle_material() -> StandardMaterial3D:
	if _cache.has("muscle"):
		return _cache["muscle"]
		
	var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	var col_red := Color(0.85, 0.12, 0.15)
	var col_white := Color(0.95, 0.95, 0.95)
	
	for y in range(64):
		for x in range(128):
			# Dual center white racing stripes
			if (y >= 26 and y <= 29) or (y >= 35 and y <= 38):
				img.set_pixel(x, y, col_white)
			else:
				img.set_pixel(x, y, col_red)
				
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.2
	mat.metallic = 0.6
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_cache["muscle"] = mat
	return mat

static func get_tire_material() -> StandardMaterial3D:
	if _cache.has("tire"):
		return _cache["tire"]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.13)
	mat.roughness = 0.9
	_cache["tire"] = mat
	return mat

static func get_rim_material() -> StandardMaterial3D:
	if _cache.has("rim"):
		return _cache["rim"]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.85, 0.88)
	mat.metallic = 0.9
	mat.roughness = 0.15
	_cache["rim"] = mat
	return mat

static func get_glass_material() -> StandardMaterial3D:
	if _cache.has("glass"):
		return _cache["glass"]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.35, 0.45, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.5
	mat.roughness = 0.1
	_cache["glass"] = mat
	return mat

static func get_glow_material(col: Color, energy: float = 3.0) -> StandardMaterial3D:
	var key := "glow_%s_%f" % [col.to_html(), energy]
	if _cache.has(key):
		return _cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	_cache[key] = mat
	return mat

static func get_grass_material() -> StandardMaterial3D:
	if _cache.has("grass"):
		return _cache["grass"]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.52, 0.22)
	mat.roughness = 0.95
	_cache["grass"] = mat
	return mat

static func get_kiosk_roof_material() -> StandardMaterial3D:
	if _cache.has("kiosk_roof"):
		return _cache["kiosk_roof"]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.65, 0.85) # Blue corrugated iron mabati
	mat.metallic = 0.4
	mat.roughness = 0.6
	_cache["kiosk_roof"] = mat
	return mat
