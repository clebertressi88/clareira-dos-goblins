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

static func build(parent: Node3D) -> void:
	var handle := _mat(Color("#8c4c28"))
	var handle_highlight := _mat(Color("#b8763d"))
	var blade := _mat(Color("#b77a3f"))
	var blade_edge := _mat(Color("#e2a55c"))
	var blade_grain := _mat(Color("#82502b"))
	var rope := _mat(Color("#dec397"))
	var rope_shadow := _mat(Color("#a68a66"))
	# Cabo alongado, levemente afunilado e com pomo arredondado.
	_tube(parent,Vector3(0,-.49,0),Vector3(-.025,-.07,0),.050,handle)
	_tube(parent,Vector3(-.025,-.07,0),Vector3(.006,.46,0),.060,handle)
	_ellipsoid(parent,Vector3(0,-.48,0),Vector3(.060,.058,.057),handle_highlight)
	_ellipsoid(parent,Vector3(.006,.455,0),Vector3(.070,.075,.067),handle_highlight)
	# Uma unica cabeca de madeira moldada com a silhueta aprovada.
	_part(parent,_blade_geometry(),Vector3.ZERO,blade)
	# Fio estreito mais claro: recortado, sem material metalico.
	_tube(parent,Vector3(-.505,.205,.006),Vector3(-.548,.300,.006),.011,blade_edge,8)
	_tube(parent,Vector3(-.548,.300,.006),Vector3(-.495,.448,.006),.011,blade_edge,8)
	# Fibras discretas nas duas faces do entalhe.
	for side in [-1.0,1.0]:
		_tube(parent,Vector3(-.40,.340,side*.032),Vector3(-.23,.310,side*.064),.005,blade_grain,6)
		_tube(parent,Vector3(-.36,.375,side*.043),Vector3(-.20,.358,side*.068),.004,blade_grain,6)
		# Corda REAL em X cruzando a face do machado.
		var z: float = float(side) * 0.093
		_tube(parent,Vector3(-.075,.454,z),Vector3(.081,.250,z),.017,rope)
		_tube(parent,Vector3(.081,.450,z+.006*side),Vector3(-.073,.254,z+.006*side),.017,rope_shadow)
	# Cordas firmes acima e abaixo do encaixe.
	for y in [.480,.493,.233,.219]:
		_tube(parent,Vector3(-.073,y,.035),Vector3(.078,y,.035),.014,rope)
		_tube(parent,Vector3(-.073,y,-.035),Vector3(.078,y,-.035),.014,rope)
