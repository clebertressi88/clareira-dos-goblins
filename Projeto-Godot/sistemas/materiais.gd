extends RefCounted
## Texturas e materiais procedurais compartilhados.
## Chamado pelos wrappers em main.gd para preservar o comportamento do jogo.

static func character_texture(family: String, surface_textures: Dictionary) -> ImageTexture:
	if surface_textures.has(family):
		return surface_textures[family]
	const SIZE := 128
	var image := Image.create_empty(SIZE,SIZE,false,Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 507
	noise.frequency = .17
	for y in range(SIZE):
		for x in range(SIZE):
			var detail := noise.get_noise_2d(x,y)
			var broad := noise.get_noise_2d(x*.19+13,y*.19-11)
			var grain := noise.get_noise_2d(x*2.5,y*2.5)
			var value := .87+broad*.10+detail*.075+grain*.045
			if family=="fur":
				var strand := noise.get_noise_2d(x*5.5,y*.53+x*.13)
				value = .84+broad*.16+strand*.18+detail*.06
			elif family=="leather":
				value = .85+broad*.16+detail*.12+grain*.069
			image.set_pixel(x,y,Color(value,value,value*.984))
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	surface_textures[family] = texture
	return texture

static func material(key: String, color: Color, materials: Dictionary, surface_textures: Dictionary) -> StandardMaterial3D:
	if not materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = .87
		var family := ""
		if key.begins_with("sculpt_skin") or key.begins_with("goblin_cheek") or key.begins_with("goblin_brow") or key.begins_with("goblin_ear") or key=="goblin_nose":
			family = "skin"
			m.roughness = .64
		elif key.begins_with("goblin_boot") or key.begins_with("goblin_cloth") or key in ["goblin_strap","goblin_belt","goblin_waist"]:
			family = "leather"
			m.roughness = .75
		elif key.begins_with("bruma_hair") or key=="bruma_braid_light" or ((key.begins_with("wolf_") or key.begins_with("rabbit_")) and not (key.ends_with("iris") or key.ends_with("nose") or key.ends_with("inner"))):
			family = "fur"
		elif key.ends_with("iris") or key.ends_with("pupil") or key=="goblin_ivory":
			m.roughness = .27
		elif key=="goblin_brass":
			m.metallic = .38
			m.roughness = .37
		if not family.is_empty():
			m.albedo_texture = character_texture(family, surface_textures)
			m.uv1_triplanar = true
			m.uv1_triplanar_sharpness = 3.0
			m.uv1_scale = Vector3.ONE*(2.3 if family=="fur" else 1.4)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		materials[key] = m
	return materials[key]
