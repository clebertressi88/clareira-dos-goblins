extends RefCounted
## Atlas RGBA de folhas recortadas. Nao preenche as areas vazias da imagem.
## Silhuetas e nervuras visiveis, com verdes claros e escuros da referencia.
static var cached_texture: ImageTexture

static func make_texture() -> Texture2D:
	if cached_texture != null:
		return cached_texture
	const SIZE := 128
	var img := Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
	img.fill(Color(0,0,0,0))
	var colors := [
		Color("#4e9b32"),Color("#77b939"),Color("#9ad348"),
		Color("#5aa832"),Color("#b1dc58"),Color("#368529"),
		Color("#8bc74b"),Color("#66b33c")
	]
	# Oito folhas distribuídas como um ramo. Fundo transparente.
	var centers := [
		Vector2(35,31),Vector2(67,20),Vector2(94,34),Vector2(25,61),
		Vector2(59,61),Vector2(99,68),Vector2(42,100),Vector2(80,101)
	]
	var angles := [-1.0,-0.25,0.63,-2.0,0.4,1.75,2.4,0.98]
	for i in range(centers.size()):
		_draw_leaf(img,centers[i],angles[i],float(19 + (i%3)*3),colors[i])
	cached_texture = ImageTexture.create_from_image(img)
	return cached_texture

static func _draw_leaf(img: Image, center: Vector2, angle: float, length: float, tone: Color) -> void:
	var direction := Vector2(cos(angle),sin(angle))
	var side := Vector2(-direction.y,direction.x)
	var radius := int(ceil(length*1.08))
	for y in range(-radius,radius+1):
		for x in range(-radius,radius+1):
			var offset := Vector2(x,y)
			var longitudinal := offset.dot(direction)/length
			if absf(longitudinal)>=1.0:
				continue
			var transverse := offset.dot(side)/(length*.46)
			var outline := pow(1.0-absf(longitudinal),0.7)
			if absf(transverse)>outline:
				continue
			var shade := 0.80+0.18*(1.0-absf(transverse)/maxf(outline,0.01))
			if absf(transverse)<.06:
				shade += .15
			# Nervuras laterais simples, sem textura plana de esfera.
			var vein := absf(transverse-0.35*sin(longitudinal*15.0))
			if vein < .027:
				shade += .055
			var px := int(center.x)+x
			var py := int(center.y)+y
			if px>=0 and py>=0 and px<img.get_width() and py<img.get_height():
				img.set_pixel(px,py,Color(
					clampf(tone.r*shade,0,1),
					clampf(tone.g*shade,0,1),
					clampf(tone.b*shade,0,1),1))
