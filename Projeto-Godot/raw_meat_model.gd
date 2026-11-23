extends RefCounted
## Carne crua encontrada no chao: pernil irregular de lobo e cortes menores de coelho.
## Sem disco achatado, riscos decorativos nem forma de ovo. Ambos ainda sao "Carne".

static func _mat(tint: Color, shine: float = 0.81) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = shine
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func _tube(parent: Node3D, start: Vector3, finish: Vector3, width: float, mat: Material) -> void:
	var axis: Vector3 = finish - start
	if axis.length_squared() < 0.000001:
		return
	var shape := CylinderMesh.new()
	shape.top_radius = width
	shape.bottom_radius = width * 1.08
	shape.height = axis.length()
	shape.radial_segments = 8
	var part := MeshInstance3D.new()
	part.mesh = shape
	part.material_override = mat
	part.position = (start + finish) * 0.5
	part.quaternion = Quaternion(Vector3.UP, axis.normalized())
	parent.add_child(part)

static func _blob(parent: Node3D, pos: Vector3, scale_value: Vector3, mat: Material) -> void:
	var shape := SphereMesh.new()
	shape.radial_segments = 12
	shape.rings = 8
	var part := MeshInstance3D.new()
	part.mesh = shape
	part.position = pos
	part.scale = scale_value
	part.material_override = mat
	parent.add_child(part)

static func _shell_point(index: int, step: int, length: float, height: float,
		depth: float, center: Vector3, phase: float) -> Vector3:
	# O raio muda de forma abrupta em cada secao: carne de verdade nao e elipsoide.
	var profile := PackedFloat32Array([0.45,0.68,0.96,1.08,1.0,0.88,0.58,0.24])
	var u: float = float(index) / 7.0
	var angle: float = TAU * float(step) / 12.0
	var uneven: float = 1.0 + sin(angle*3.0 + float(index)*0.61 + phase)*0.095
	uneven += cos(angle*5.0 - float(index)*0.39 + phase)*0.055
	var radius: float = profile[index] * uneven
	var x: float = center.x + (u - 0.5) * length + sin(angle*2.0 + u*6.0 + phase)*0.012
	var y: float = center.y + sin(u*PI)*0.015 + sin(angle)*height*radius
	var z: float = center.z + cos(angle)*depth*radius
	return Vector3(x, maxf(y,0.022), z)

static func _raw_chunk(parent: Node3D, center: Vector3, length: float, height: float,
		depth: float, muscle: Material, cut: Material, phase: float) -> void:
	# Malha fechada, volumetrica e triangulada; faces nas pontas parecem cortes de musculo.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for section in range(7):
		for step in range(12):
			var a: Vector3 = _shell_point(section,step,length,height,depth,center,phase)
			var b: Vector3 = _shell_point(section+1,step,length,height,depth,center,phase)
			var c: Vector3 = _shell_point(section,step+1,length,height,depth,center,phase)
			var d: Vector3 = _shell_point(section+1,step+1,length,height,depth,center,phase)
			for vertex in [a,b,c,c,b,d]:
				surface.add_vertex(vertex)
	surface.generate_normals()
	var body := MeshInstance3D.new()
	body.mesh = surface.commit()
	body.material_override = muscle
	parent.add_child(body)
	# Extremidade seccionada, mais escura, em vez de um contorno liso rosado.
	var face := SurfaceTool.new()
	face.begin(Mesh.PRIMITIVE_TRIANGLES)
	for step in range(12):
		var outer_a: Vector3 = _shell_point(0,step,length,height,depth,center,phase)
		var outer_b: Vector3 = _shell_point(0,step+1,length,height,depth,center,phase)
		var central := center + Vector3(-length*0.5+0.003,0,0)
		for vertex in [central,outer_b,outer_a]:
			face.add_vertex(vertex)
	face.generate_normals()
	var cut_surface := MeshInstance3D.new()
	cut_surface.mesh = face.commit()
	cut_surface.material_override = cut
	parent.add_child(cut_surface)

static func _bone(parent: Node3D, start: Vector3, end: Vector3,
		radius: float, ivory: Material, joint: Material) -> void:
	_tube(parent,start,end,radius,ivory)
	_blob(parent,end,Vector3(radius*1.7,radius*1.45,radius*1.8),ivory)
	_blob(parent,end+Vector3(0,0,radius*0.9),Vector3(radius*1.0,radius*1.3,radius*1.25),joint)
	_blob(parent,end+Vector3(0,0,-radius*0.9),Vector3(radius*1.0,radius*1.3,radius*1.25),joint)

static func build(parent: Node3D, from_rabbit: bool = false) -> void:
	var main_flesh := _mat(Color("#a74d55") if from_rabbit else Color("#823034"),0.72)
	var torn := _mat(Color("#c47b76") if from_rabbit else Color("#b65355"),0.76)
	var deep_cut := _mat(Color("#8b4248") if from_rabbit else Color("#5b1e27"),0.80)
	var fat := _mat(Color("#e0b9a6") if from_rabbit else Color("#d8b3a0"),0.82)
	var connective := _mat(Color("#b78d82") if from_rabbit else Color("#a36b66"),0.83)
	var ivory := _mat(Color("#e3d8bc"),0.89)
	var bone_joint := _mat(Color("#ccbea3"),0.87)
	if from_rabbit:
		# Coelho: dois cortes pequenos e rosados, com tecido e osso mais fino.
		_raw_chunk(parent,Vector3(-0.065,0.085,-0.038),0.245,0.060,0.078,
			main_flesh,deep_cut,0.7)
		_raw_chunk(parent,Vector3(0.058,0.075,0.052),0.173,0.048,0.052,
			torn,deep_cut,1.9)
		_blob(parent,Vector3(-0.061,0.136,-0.017),Vector3(0.069,0.016,0.043),torn)
		_blob(parent,Vector3(0.018,0.116,0.073),Vector3(0.042,0.013,0.031),connective)
		_bone(parent,Vector3(0.13,0.084,-0.03),Vector3(0.233,0.102,-0.028),
			0.014,ivory,bone_joint)
		_blob(parent,Vector3(0.138,0.10,-0.03),Vector3(0.030,0.022,0.025),connective)
		_blob(parent,Vector3(-0.130,0.084,0.022),Vector3(0.043,0.020,0.022),fat)
		# Pequenos feixes ao redor da articulação, sem listras flutuantes.
		_blob(parent,Vector3(-0.107,0.109,-0.062),Vector3(0.055,0.018,0.029),connective)
		_blob(parent,Vector3(0.080,0.090,0.070),Vector3(0.043,0.016,0.025),fat)
		_blob(parent,Vector3(-0.015,0.132,-0.018),Vector3(0.040,0.020,0.028),torn)
	else:
		# Lobo: quarto traseiro rasgado, alto e pesado, com osso saindo da carne.
		_raw_chunk(parent,Vector3(-0.047,0.135,-0.018),0.445,0.104,0.119,
			main_flesh,deep_cut,0.5)
		_raw_chunk(parent,Vector3(-0.115,0.099,0.084),0.287,0.071,0.072,
			torn,deep_cut,2.2)
		# Lobulos musculares em alturas diferentes: rompem a silhueta de bisteca plana.
		_blob(parent,Vector3(-0.135,0.219,-0.049),
			Vector3(0.102,0.040,0.063),torn)
		_blob(parent,Vector3(0.019,0.207,0.037),
			Vector3(0.092,0.035,0.059),main_flesh)
		_blob(parent,Vector3(-0.163,0.150,0.101),
			Vector3(0.075,0.034,0.031),deep_cut)
		# A gordura fica incrustada nos rasgos, nao desenhada como listras.
		_blob(parent,Vector3(-0.175,0.163,-0.075),
			Vector3(0.073,0.018,0.026),fat)
		_blob(parent,Vector3(0.075,0.181,-0.105),
			Vector3(0.057,0.017,0.025),connective)
		_blob(parent,Vector3(-0.089,0.215,0.054),
			Vector3(0.054,0.013,0.026),connective)
		# Femur exposto com duas saliencias na junta: identifica imediatamente carne crua.
		_bone(parent,Vector3(0.123,0.141,-0.009),Vector3(0.378,0.166,-0.009),
			0.029,ivory,bone_joint)
		_blob(parent,Vector3(0.151,0.142,-0.008),
			Vector3(0.052,0.046,0.049),deep_cut)
		_blob(parent,Vector3(0.167,0.153,-0.008),
			Vector3(0.031,0.035,0.037),connective)
