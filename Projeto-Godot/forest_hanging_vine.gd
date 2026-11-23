extends RefCounted
## Cipo pendurado nas folhas: caule sinuoso, ramos e folhas em formato de gota.
## Modelo local: nasce em y=0 e desce; sem colisao no caule fino.
static func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.96
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func _leaf_texture() -> ImageTexture:
	# Padrao de verde irregular + nervuras claras, gerado sem arquivo externo.
	var img := Image.create(64,64,false,Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var u := float(x)/63.0
			var v := float(y)/63.0
			var shade: float = 0.84+0.12*sin(u*38.0+v*13.0)*sin(v*31.0)
			var vein_distance: float = absf(u-0.5)
			if vein_distance<0.035:
				shade += 0.17
			elif abs(v-(0.16+abs(u-0.5)*0.92))<0.021 or abs(v-(0.84-abs(u-0.5)*0.92))<0.021:
				shade += 0.10
			img.set_pixel(x,y,Color(0.47*shade,0.69*shade,0.37*shade,1.0))
	return ImageTexture.create_from_image(img)

static func _stem(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
	var delta := b-a
	var tube := CylinderMesh.new()
	tube.top_radius = radius * 0.82
	tube.bottom_radius = radius
	tube.height = delta.length()
	tube.radial_segments = 7
	var segment := MeshInstance3D.new()
	segment.mesh = tube
	segment.material_override = mat
	segment.position = (a+b)*0.5
	segment.quaternion = Quaternion(Vector3.UP,delta.normalized())
	parent.add_child(segment)

static func build(parent: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(seed)
	var stem := _mat(Color("#496b35"))
	var stem_light := _mat(Color("#718d3b"))
	var leaf := _mat(Color("#477b39"))
	var leaf_light := _mat(Color("#78a54b"))
	var leaf_texture := _leaf_texture()
	leaf.albedo_texture = leaf_texture
	leaf_light.albedo_texture = leaf_texture
	var vein := _mat(Color("#a2bd63"))
	var last := Vector3.ZERO
	var length := rng.randf_range(0.95,1.48)
	var side := rng.randf_range(0.06,0.12)
	for i in range(1,10):
		var t := float(i)/9.0
		var p := Vector3(sin(t*TAU*1.2)*side,-length*t,cos(t*TAU)*side*0.5)
		_stem(parent,last,p,lerpf(0.030,0.011,t),stem)
		if i in [2,4,6,8]:
			for sign_dir in [-1.0,1.0]:
				var direction := Vector3(sign_dir,rng.randf_range(-0.32,-0.07),rng.randf_range(-0.35,0.35)).normalized()
				var tip := p+direction*rng.randf_range(0.15,0.27)
				_stem(parent,p,tip,0.009,stem_light)
				var blade := SphereMesh.new()
				blade.radius = 0.1
				blade.height = 0.2
				blade.radial_segments = 8
				blade.rings = 4
				var mesh := MeshInstance3D.new()
				mesh.mesh = blade
				mesh.material_override = leaf if (i+int(sign_dir))%3 else leaf_light
				mesh.position = tip+direction*0.09
				mesh.scale = Vector3(0.60,1.45,0.25)
				mesh.quaternion = Quaternion(Vector3.UP,direction)
				parent.add_child(mesh)
				_stem(parent,tip,tip+direction*0.13,0.005,vein)
		last = p
