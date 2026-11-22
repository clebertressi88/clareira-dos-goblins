extends RefCounted
## Textura de folhagem verde natural, gerada no Godot sem arquivo externo.
## Pequenas folhas sobrepostas inspiradas na referencia do usuario.
static var cached_texture: ImageTexture

static func make_texture() -> Texture2D:
	if cached_texture != null:
		return cached_texture
	const SIZE := 256
	var img := Image.create(SIZE,SIZE,false,Image.FORMAT_RGB8)
	img.fill(Color("#244624"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261122
	for layer in range(2):
		var leaves := 175 if layer == 0 else 125
		for i in range(leaves):
			var center := Vector2(rng.randf_range(0,SIZE),rng.randf_range(0,SIZE))
			var angle := rng.randf_range(0,TAU)
			var size := rng.randf_range(6.0,12.0) if layer == 0 else rng.randf_range(8.0,15.0)
			var tones := [Color("#2d602a"),Color("#3e772f"),Color("#4e8b36"),Color("#66a441"),Color("#87bd4b"),Color("#a5d85d")]
			var tone := tones[rng.randi_range(0,2)] if layer == 0 else tones[rng.randi_range(2,5)]
			_draw_leaf(img,center,angle,size,tone)
	cached_texture = ImageTexture.create_from_image(img)
	return cached_texture

static func _draw_leaf(img: Image, center: Vector2, angle: float, size: float, tone: Color) -> void:
	var direction := Vector2(cos(angle),sin(angle))
	var side := Vector2(-direction.y,direction.x)
	var radius := int(ceil(size * 1.2))
	for y in range(-radius,radius + 1):
		for x in range(-radius,radius + 1):
			var offset := Vector2(x,y)
			var forward := offset.dot(direction) / size
			var across := offset.dot(side) / (size * 0.41)
			var profile := 1.0 - absf(forward)
			if profile <= 0.0 or absf(across) >= sin(profile * PI * 0.5):
				continue
			var shade := 0.82 + 0.18 * (1.0 - absf(across))
			if absf(across) < 0.095:
				shade += 0.10
			var px := posmod(int(center.x) + x,img.get_width())
			var py := posmod(int(center.y) + y,img.get_height())
			img.set_pixel(px,py,tone * shade)
