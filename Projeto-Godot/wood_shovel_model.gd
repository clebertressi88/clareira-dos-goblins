extends RefCounted
## Pa de madeira artesanal: concha curva, nervuras entalhadas e corda em X.
## Modelo unico para a mao e para item largado no terreno.

static func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.91
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func _part(parent: Node3D, mesh: Mesh, position: Vector3, mat: Material) -> MeshInstance3D:
	var p := MeshInstance3D.new()
	p.mesh = mesh
	p.position = position
	p.material_override = mat
	parent.add_child(p)
	return p

static func _tube(parent: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, sides: int = 9) -> void:
	var direction: Vector3 = b - a
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = direction.length()
	cyl.radial_segments = sides
	var piece := _part(parent, cyl, (a + b) * 0.5, mat)
	piece.quaternion = Quaternion(Vector3.UP, direction.normalized())

static func _stroke(parent: Node3D, points: Array[Vector3], r: float, mat: Material) -> void:
	for i in range(points.size() - 1):
		_tube(parent, points[i], points[i + 1], r, mat, 6)

static func _blade_mesh() -> ArrayMesh:
	# 12 secoes sobre o comprimento e 8 sobre a largura:
	# a depressao central recua no eixo Z, criando uma concha verdadeira.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: int = 12
	var cols: int = 8
	for row in range(rows):
		var u0: float = float(row) / float(rows)
		var u1: float = float(row + 1) / float(rows)
		for col in range(cols):
			var v0: float = float(col) / float(cols) * 2.0 - 1.0
			var v1: float = float(col + 1) / float(cols) * 2.0 - 1.0
			var a: Vector3 = _blade_point(u0, v0)
			var b: Vector3 = _blade_point(u0, v1)
			var c: Vector3 = _blade_point(u1, v0)
			var d: Vector3 = _blade_point(u1, v1)
			for vertex in [a, c, b, b, c, d]:
				surface.set_uv(Vector2(vertex.x + 0.5, vertex.y))
				surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()

static func _blade_point(u: float, v: float) -> Vector3:
	var width: float = 0.155 * (0.70 + 0.30 * sin(PI * u))
	width *= (1.0 - 0.17 * pow(u, 5.0))
	var y: float = 0.21 + u * 0.46 - 0.028 * absf(v) * u
	var x: float = v * width
	var dish: float = 0.060 * (1.0 - v * v) * sin(PI * (0.15 + u * 0.80))
	var z: float = -dish + 0.025 * absf(v) + 0.022 * u
	return Vector3(x, y, z)

static func _wrap(parent: Node3D, center_y: float, turns: float, span: float, radius: float, mat: Material) -> void:
	var count: int = int(22.0 * turns)
	for i in range(count):
		var a: float = TAU * float(i) / 22.0
		var b: float = TAU * float(i + 1) / 22.0
		var y0: float = center_y + span * (float(i) / float(count) - 0.5)
		var y1: float = center_y + span * (float(i + 1) / float(count) - 0.5)
		_tube(parent, Vector3(cos(a) * radius,y0,sin(a) * radius),
			Vector3(cos(b) * radius,y1,sin(b) * radius),0.009,mat,6)

static func build(parent: Node3D) -> void:
	var wood := _mat(Color("#815033"))
	var light := _mat(Color("#b37a48"))
	var dark := _mat(Color("#59331f"))
	var blade := _mat(Color("#b7884f"))
	var edge := _mat(Color("#d0a36b"))
	var groove := _mat(Color("#764b2c"))
	var rope := _mat(Color("#dabe84"))
	var shadow := _mat(Color("#a88b58"))
	# Cabo levemente curvo, empunhadura arredondada e veios aparentes.
	_tube(parent,Vector3(0,-0.52,0),Vector3(-0.017,-0.22,0),0.049,wood,12)
	_tube(parent,Vector3(-0.017,-0.22,0),Vector3(0.003,0.18,0),0.042,light,12)
	_tube(parent,Vector3(0.003,0.18,0),Vector3(0.004,0.34,0),0.051,wood,12)
	var pommel := SphereMesh.new()
	pommel.radial_segments = 12
	pommel.rings = 8
	var knob := _part(parent,pommel,Vector3(0,-0.53,0),dark)
	knob.scale = Vector3(0.068,0.065,0.063)
	for side in [-1.0,1.0]:
		var z: float = float(side) * 0.045
		_stroke(parent,[Vector3(-0.019,-0.43,z),Vector3(-0.028,-0.29,z),Vector3(-0.010,-0.14,z)],0.003,dark)
		_stroke(parent,[Vector3(0.024,-0.39,z),Vector3(0.017,-0.26,z),Vector3(0.013,-0.10,z)],0.0025,light)
	# Concha côncava, não uma caixa reta.
	_part(parent,_blade_mesh(),Vector3.ZERO,blade)
	# Arestas reforcadas, lascas nas laterais e veios internos curvos.
	for side in [-1.0,1.0]:
		var rim: Array[Vector3] = []
		for k in range(13):
			rim.append(_blade_point(float(k) / 12.0,float(side)))
		_stroke(parent,rim,0.009,edge)
	for lateral in [-0.72,-0.38,0.0,0.38,0.72]:
		var vein: Array[Vector3] = []
		for k in range(2,12):
			var u: float = float(k) / 12.0
			var p: Vector3 = _blade_point(u,float(lateral))
			p.z -= 0.004
			vein.append(p)
		_stroke(parent,vein,0.0028 if lateral != 0.0 else 0.004,groove)
	# Reforcos laterais e amarracao que une a concha ao cabo.
	_tube(parent,Vector3(-0.12,0.23,0.026),Vector3(-0.08,0.44,0.034),0.013,light,8)
	_tube(parent,Vector3(0.12,0.23,0.026),Vector3(0.08,0.44,0.034),0.013,light,8)
	for side in [-1.0,1.0]:
		var face_z: float = float(side) * 0.074
		_tube(parent,Vector3(-0.090,0.28,face_z),Vector3(0.085,0.12,face_z),0.013,rope,8)
		_tube(parent,Vector3(0.088,0.28,face_z + float(side)*0.010),Vector3(-0.087,0.12,face_z + float(side)*0.010),0.013,shadow,8)
	_wrap(parent,0.13,2.0,0.065,0.060,rope)
	_wrap(parent,0.29,2.0,0.058,0.061,rope)
	_wrap(parent,-0.45,1.6,0.053,0.056,rope)
