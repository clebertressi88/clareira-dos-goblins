extends RefCounted
# Bancadas goblin com malhas 3D leves e materiais procedurais.
# Ponto de origem na base dos pes; as duas variantes preservam os IDs antigos.
static func build(parent: Node3D, advanced: bool) -> void:
	var width := 1.32 if advanced else 1.12
	var depth := 0.88 if advanced else 0.76
	var top_y := 0.91 if advanced else 0.79
	var dark := Color("#50341f")
	var timber := Color("#855633")
	var pale := Color("#b4814d")
	var iron := Color("#53575b")
	for x_sign in [-1.0,1.0]:
		for z_sign in [-1.0,1.0]:
			var x := x_sign*(width*0.5-0.12)
			var z := z_sign*(depth*0.5-0.11)
			_cylinder(parent,Vector3(x,top_y*0.49,z),0.084,top_y*0.98,timber)
			_cylinder(parent,Vector3(x,top_y*0.23,z),0.093,0.10,dark)
			# Amarras grossas nas juntas; no nivel 2, ferragens de reforco.
			_cylinder(parent,Vector3(x,top_y-0.13,z),0.103,0.055,iron if advanced else Color("#ac8b55"))
	# Longarinas e prateleira inferior.
	for z_sign in [-1.0,1.0]:
		_box(parent,Vector3(0,0.27,z_sign*(depth*0.5-0.11)),Vector3(width-0.16,0.085,0.085),dark)
	for x_sign in [-1.0,1.0]:
		_box(parent,Vector3(x_sign*(width*0.5-0.11),0.41,0),Vector3(0.08,0.10,depth-0.11),dark)
	for i in range(3):
		_box(parent,Vector3(0,0.29,(float(i)-1.0)*0.19),Vector3(width-0.25,0.053,0.155),Color("#79502f"))
	# Travessas diagonais visiveis, presas aos pes e sem sair da colisao.
	for z_sign in [-1.0,1.0]:
		var brace := _box(parent,Vector3(0,0.47,z_sign*(depth*0.5-0.11)),Vector3(width-0.26,0.055,0.055),dark)
		brace.rotation.z = 0.43 if z_sign>0.0 else -0.43
	# Tampo irregular: tabuas individuais ligeiramente desniveladas.
	for i in range(5):
		var z := (float(i)-2.0)*(depth/5.0)
		var rise := 0.008 if i%2==0 else -0.006
		var plank_color := Color("#9c663a") if i%2==0 else pale
		if advanced:
			plank_color = Color("#78502f") if i%2==0 else Color("#95643b")
		_box(parent,Vector3(0,top_y+rise,z),Vector3(width-0.025,0.13,depth/5.0-0.009),plank_color)
		# Textura de fibra em tiras discretas sobre cada prancha.
		for line in range(2):
			_box(parent,Vector3((-0.19 if line==0 else 0.23),top_y+0.071+rise,z),Vector3(width*0.36,0.003,0.009),Color("#70482b"))
	# Borda e encaixes das extremidades.
	for x_sign in [-1.0,1.0]:
		_box(parent,Vector3(x_sign*(width*0.5-0.025),top_y,0),Vector3(0.035,0.16,depth),dark)
	if advanced:
		# Placa de pedra reforcada e bigorna de trabalho ao fundo.
		_box(parent,Vector3(0.17,top_y+0.103,-0.13),Vector3(width*0.52,0.075,depth*0.49),Color("#707573"))
		for seam in [-0.15,0.14]:
			_box(parent,Vector3(0.17+seam,top_y+0.144,-0.13),Vector3(0.014,0.004,depth*0.40),Color("#464d4b"))
		_box(parent,Vector3(-0.34,top_y+0.105,0.17),Vector3(0.21,0.09,0.17),iron)
		# Ferragens nas bordas e suportes das ferramentas.
		for x_sign in [-1.0,1.0]:
			_box(parent,Vector3(x_sign*(width*0.5-0.13),top_y+0.080,0),Vector3(0.045,0.024,depth*0.88),iron)
		# Pequeno rack de ferramentas, atras da bancada.
		for x_sign in [-1.0,1.0]:
			_box(parent,Vector3(x_sign*0.49,1.12,-depth*0.43),Vector3(0.075,0.46,0.075),dark)
		_box(parent,Vector3(0,1.29,-depth*0.43),Vector3(1.05,0.075,0.08),timber)
		for x in [-0.28,0.0,0.29]:
			_box(parent,Vector3(x,1.12,-depth*0.42),Vector3(0.038,0.27,0.045),Color("#777c7b"))
		# Pote de fragmentos de rocha e pequenas pecas.
		_cylinder(parent,Vector3(-0.12,top_y+0.14,0.25),0.075,0.12,Color("#67503a"))
		_box(parent,Vector3(-0.12,top_y+0.21,0.25),Vector3(0.09,0.07,0.09),Color("#939a95"))
	else:
		# Ferramentas simples e rolo de corda repousam no canto.
		_box(parent,Vector3(-0.30,top_y+0.094,-0.15),Vector3(0.37,0.032,0.037),Color("#624128"))
		_box(parent,Vector3(-0.45,top_y+0.112,-0.15),Vector3(0.10,0.055,0.09),Color("#92908a"))
		_cylinder(parent,Vector3(0.36,top_y+0.115,0.17),0.091,0.078,Color("#b9a070"))
		_cylinder(parent,Vector3(0.36,top_y+0.16,0.17),0.043,0.01,Color("#6c5135"))

static func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _part(parent,mesh,pos,color)

static func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius*0.93
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 9
	return _part(parent,mesh,pos,color)

static func _part(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	part.material_override = mat
	parent.add_child(part)
	return part
