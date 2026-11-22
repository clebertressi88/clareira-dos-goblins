extends RefCounted
# Texturas procedurais reutilizaveis: sem imagens externas e sem depender de downloads.
static var cache: Dictionary = {}

static func texture_for(family: String) -> ImageTexture:
	if cache.has(family):
		return cache[family]
	var size := 128
	var img := Image.create_empty(size,size,false,Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 1946 if family=="wood" else (5791 if family=="roof" else 4327)
	noise.frequency = .065
	for y in range(size):
		for x in range(size):
			var broad := noise.get_noise_2d(float(x)*.31,float(y)*.31)
			var fine := noise.get_noise_2d(float(x)*2.8,float(y)*2.8)
			var shade := 0.83+broad*.16+fine*.07
			if family=="wood":
				# Veios alongados com nos, pequenas fissuras e variacao de tabuas.
				var grain := noise.get_noise_2d(float(x)*.14,float(y)*1.9)
				var knots := noise.get_noise_2d(float(x)*.035+27.,float(y)*.08)
				shade = .77+grain*.16+knots*.11+fine*.08
				if int(x+int(knots*8.0))%37<=1:
					shade *= .72
			elif family=="roof":
				var strip := noise.get_noise_2d(float(x)*.95,float(y)*.27)
				shade = .73+strip*.14+broad*.16+fine*.13
				if (x+int(broad*5.0))%23==0:
					shade *= .72
			else:
				var pores := noise.get_noise_2d(float(x)*3.1,float(y)*3.1)
				shade = .83+broad*.16+pores*.07+fine*.07
			shade = clampf(shade,.35,1.0)
			img.set_pixel(x,y,Color(shade,shade*.985,shade*.94))
	img.generate_mipmaps()
	var result := ImageTexture.create_from_image(img)
	cache[family] = result
	return result

static func apply(game, visual: MeshInstance3D, family: String, tint: Color) -> void:
	var name := "goblin_cabin_%s_%s" % [family,tint.to_html(false)]
	var mat: StandardMaterial3D = game.material(name,tint)
	mat.albedo_texture = texture_for(family)
	mat.uv1_triplanar = true
	mat.uv1_triplanar_sharpness = 3.0
	mat.uv1_scale = Vector3(1.3,1.8,1.3) if family=="wood" else (Vector3(2.0,1.8,2.0) if family=="roof" else Vector3.ONE*1.35)
	mat.roughness = .98
	mat.metallic = 0.0
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	visual.material_override = mat
