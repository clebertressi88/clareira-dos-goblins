extends RefCounted
## Machado de madeira aprovado: lamina larga a esquerda, contrapeso menor a direita,
## cabo curvo castanho e corda em X. Um unico modelo para mao e para item dropado.
## Eixo Y = cabo. Frente da lamina = Z positivo; fio cortante = X negativo.

static func _mat(color: Color, rough: float = 0.87) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func _part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var p := MeshInstance3D.new()
	p.mesh = mesh
	p.material_override = mat
	p.position = pos
	parent.add_child(p)
	return p

static func _tube(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material, sides: int = 10) -> void:
	var d := b-a
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = d.length()
	cyl.radial_segments = sides
	var part := _part(parent,cyl,(a+b)*0.5,mat)
	part.quaternion = Quaternion(Vector3.UP,d.normalized())

static func _ellipsoid(parent: Node3D, pos: Vector3, scale_value: Vector3, mat: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 7
	var p := _part(parent,mesh,pos,mat)
	p.scale = scale_value

static func _blade_geometry() -> ArrayMesh:
	# A lamina possui um corte concavo superior/inferior e um fio largo a esquerda.
	# Perto do encaixe ha um pequeno contrapeso, como na referencia do Blender.
	var profile := PackedVector2Array([
		Vector2(-.495,.450),Vector2(-.420,.430),Vector2(-.280,.408),
		Vector2(-.130,.428),Vector2(-.045,.440),Vector2(.080,.445),
		Vector2(.190,.470),Vector2(.265,.375),Vector2(.222,.240),
		Vector2(.092,.225),Vector2(-.050,.235),Vector2(-.165,.232),
		Vector2(-.287,.175),Vector2(-.388,.110),Vector2(-.505,.200),
		Vector2(-.545,.300)
	])
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector2(-.115,.317)
	for i in range(profile.size()):
		var a := profile[i]
		var b := profile[(i+1)%profile.size()]
		var thick_a := lerpf(.010,.075,clampf((a.x+.54)/.43,0.0,1.0))
		var thick_b := lerpf(.010,.075,clampf((b.x+.54)/.43,0.0,1.0))
		for side in [-1.0,1.0]:
			var middle := Vector3(center.x,center.y,side*.078)
			var pa := Vector3(a.x,a.y,side*thick_a)
			var pb := Vector3(b.x,b.y,side*thick_b)
			for v in [middle,pa,pb]:
				s.set_uv(Vector2(v.x+0.6,v.y))
				s.add_vertex(v)
		var a_back := Vector3(a.x,a.y,-thick_a)
		var b_back := Vector3(b.x,b.y,-thick_b)
		var a_front := Vector3(a.x,a.y,thick_a)
		var b_front := Vector3(b.x,b.y,thick_b)
		for v in [a_back,b_back,a_front,b_back,b_front,a_front]:
			s.set_uv(Vector2(v.x+0.6,v.y))
			s.add_vertex(v)
	s.generate_normals()
	return s.commit()


# Curvas de entalhe, veio ou fibra criadas com pequenos segmentos de madeira.
static func _stroke(parent: Node3D, points: Array[Vector3], thickness: float, mat: Material) -> void:
	for i in range(points.size() - 1):
		_tube(parent, points[i], points[i + 1], thickness, mat, 6)

# Cordame torcido seguindo um cabo arredondado; cada volta tem volume real.
static func _wrap(parent: Node3D, y_center: float, turns: float, width: float, mat: Material) -> void:
	var segments: int = int(24.0 * turns)
	for i in range(segments):
		var a: float = TAU * float(i) / 24.0
		var b: float = TAU * float(i + 1) / 24.0
		var ya: float = y_center + width * (float(i) / float(segments) - 0.5)
		var yb: float = y_center + width * (float(i + 1) / float(segments) - 0.5)
		var ra: float = 0.070
		var rb: float = 0.070
		_tube(parent, Vector3(cos(a) * ra, ya, sin(a) * ra), Vector3(cos(b) * rb, yb, sin(b) * rb), 0.012, mat, 6)

# No das fibras da madeira em uma das duas faces da lamina.
static func _knot(parent: Node3D, x: float, y: float, z: float, mat: Material) -> void:
	var points: Array[Vector3] = []
	for i in range(13):
		var a: float = TAU * float(i) / 12.0
		points.append(Vector3(x + 0.055 * cos(a), y + 0.023 * sin(a), z))
	_stroke(parent, points, 0.0035, mat)

static func build(parent: Node3D) -> void:
	var handle := _mat(Color("#874222"))
	var handle_highlight := _mat(Color("#ae6033"))
	var handle_dark := _mat(Color("#65351e"))
	var blade := _mat(Color("#bd7935"))
	var blade_highlight := _mat(Color("#e6a24f"))
	var blade_edge := _mat(Color("#f3c277"))
	var blade_grain := _mat(Color("#885022"))
	var blade_deep := _mat(Color("#6e401f"))
	var rope := _mat(Color("#e4cb8b"))
	var rope_shadow := _mat(Color("#a58a56"))
	# Cabo: eixo organico com punho mais largo e madeira colorida em camadas.
	_tube(parent, Vector3(0.018,-0.50,0), Vector3(-0.025,-0.20,0), 0.057, handle, 12)
	_tube(parent, Vector3(-0.025,-0.20,0), Vector3(-0.010,0.08,0), 0.047, handle_highlight, 12)
	_tube(parent, Vector3(-0.010,0.08,0), Vector3(0.006,0.52,0), 0.059, handle, 12)
	_ellipsoid(parent, Vector3(0.018,-0.50,0), Vector3(0.073,0.065,0.070), handle_dark)
	_ellipsoid(parent, Vector3(0.006,0.52,0), Vector3(0.069,0.065,0.067), handle_highlight)
	# Fibras curvas longitudinais no cabo.
	for side in [-1.0,1.0]:
		var z: float = float(side) * 0.050
		_stroke(parent, [Vector3(-0.025,-0.43,z),Vector3(-0.030,-0.31,z),Vector3(-0.016,-0.18,z),Vector3(-0.014,-0.07,z)], 0.003, handle_dark)
		_stroke(parent, [Vector3(0.019,-0.40,z),Vector3(0.013,-0.27,z),Vector3(0.002,-0.12,z)], 0.003, handle_highlight)
	# Lamina larga, com entalhe concavo e contrapeso pequeno.
	_part(parent, _blade_geometry(), Vector3.ZERO, blade)
	# Borda iluminada seguindo todo o fio e topo; lascas desgastadas na aresta.
	for side in [-1.0,1.0]:
		var z: float = float(side) * 0.024
		_stroke(parent,[Vector3(-0.495,0.450,z),Vector3(-0.538,0.380,z),Vector3(-0.545,0.300,z),Vector3(-0.505,0.200,z),Vector3(-0.388,0.110,z)],0.007,blade_edge)
		_stroke(parent,[Vector3(-0.495,0.450,z),Vector3(-0.420,0.430,z),Vector3(-0.280,0.408,z)],0.004,blade_highlight)
		# Veios com varias curvas acompanhando o corte da madeira.
		var face: float = float(side) * 0.079
		_stroke(parent,[Vector3(-0.435,0.365,face),Vector3(-0.335,0.352,face),Vector3(-0.235,0.342,face),Vector3(-0.147,0.344,face)],0.004,blade_grain)
		_stroke(parent,[Vector3(-0.458,0.332,face),Vector3(-0.357,0.327,face),Vector3(-0.265,0.309,face),Vector3(-0.145,0.300,face)],0.0035,blade_deep)
		_stroke(parent,[Vector3(-0.415,0.285,face),Vector3(-0.316,0.274,face),Vector3(-0.221,0.268,face),Vector3(-0.143,0.275,face)],0.004,blade_grain)
		_stroke(parent,[Vector3(-0.345,0.383,face),Vector3(-0.271,0.380,face),Vector3(-0.205,0.371,face)],0.003,blade_highlight)
		# Nos concentricos entalhados e pequenas rachaduras nas extremidades.
		_knot(parent,-0.305,0.323,face + float(side)*0.003,blade_deep)
		_stroke(parent,[Vector3(-0.491,0.412,face),Vector3(-0.455,0.388,face),Vector3(-0.437,0.381,face)],0.003,blade_deep)
		_stroke(parent,[Vector3(-0.481,0.220,face),Vector3(-0.445,0.251,face),Vector3(-0.420,0.254,face)],0.003,blade_deep)
		# Trama volumetrica em X: cordas em diagonal na frente e no verso.
		var rope_z: float = float(side) * 0.091
		_tube(parent, Vector3(-0.083,0.479,rope_z), Vector3(0.084,0.248,rope_z),0.014,rope,10)
		_tube(parent, Vector3(0.080,0.473,rope_z + float(side)*0.010),Vector3(-0.080,0.249,rope_z + float(side)*0.010),0.014,rope_shadow,10)
		# Filamentos claros reforcam a leitura da corda torcida.
		_tube(parent, Vector3(-0.079,0.475,rope_z + float(side)*0.012),Vector3(0.088,0.244,rope_z + float(side)*0.012),0.003,blade_edge,6)
	# Duas faixas de corda em espiral junto ao encaixe, com espessura real.
	_wrap(parent,0.475,2.0,0.065,rope)
	_wrap(parent,0.243,2.5,0.072,rope)
