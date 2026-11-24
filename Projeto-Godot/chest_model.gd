extends RefCounted
# Bau de madeira com tampa articulada, ferragens e detalhes modelados.
static func build(parent: Node3D) -> void:
	var body := Node3D.new()
	body.name = "CorpoBau"
	parent.add_child(body)
	var wood := Color("#76502e")
	var dark := Color("#3b281b")
	var iron := Color("#505052")
	var edge := Color("#9b6b39")
	_box(body,Vector3(0,0.31,0),Vector3(0.97,0.53,0.58),wood)
	for i in range(4):
		var y := 0.11+float(i)*0.135
		_box(body,Vector3(0,y,0.296),Vector3(0.93,0.013,0.012),dark)
		_box(body,Vector3(0,y,-0.296),Vector3(0.93,0.013,0.012),dark)
		for z in [-0.29,0.29]:
			_box(body,Vector3(0,y,z),Vector3(0.94,0.012,0.009),edge)
	for x in [-0.41,0.41]:
		_box(body,Vector3(x,0.33,0.302),Vector3(0.065,0.57,0.039),iron)
		_box(body,Vector3(x,0.33,-0.302),Vector3(0.065,0.57,0.039),iron)
		for z in [-0.30,0.30]:
			_box(body,Vector3(x,0.08,z),Vector3(0.13,0.14,0.09),dark)
	# Tampa com pivô na borda posterior; rotacao x negativa abre para tras.
	var lid := Node3D.new()
	lid.name = "Tampa"
	lid.position = Vector3(0,0.59,-0.295)
	parent.add_child(lid)
	_box(lid,Vector3(0,0.08,0.295),Vector3(1.03,0.16,0.64),edge)
	for i in range(5):
		var x := (float(i)-2.0)*0.194
		_box(lid,Vector3(x,0.165,0.295),Vector3(0.008,0.006,0.60),dark)
	for x in [-0.43,0.43]:
		_box(lid,Vector3(x,0.174,0.295),Vector3(0.075,0.028,0.635),iron)
		_box(lid,Vector3(x,0.027,0.0),Vector3(0.14,0.09,0.085),iron)
	# Fecho frontal e placa de tranca.
	_box(body,Vector3(0,0.50,0.326),Vector3(0.23,0.19,0.035),iron)
	_box(body,Vector3(0,0.48,0.348),Vector3(0.07,0.08,0.013),Color("#c1a069"))
	# Pequenos rebites e veios estilizados.
	for x in [-0.40,0.40]:
		for y in [0.18,0.46]:
			_cylinder(body,Vector3(x,y,0.334),0.018,0.019,Color("#c0a47d"),Vector3.RIGHT.rotated(Vector3.UP,PI*0.5))
	for i in range(3):
		_box(body,Vector3(-0.30+float(i)*0.30,0.37,0.318),Vector3(0.16,0.007,0.007),dark)

static func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_add(parent,mesh,pos,color)

static func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, axis: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	_add(parent,mesh,pos,color)

static func _add(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86
	if color!=Color("#505052") and color!=Color("#c1a069"):
		mat.albedo_texture = preload("res://chest_wood_grain.svg")
		mat.uv1_scale = Vector3(1.5,1.5,1.5)
	else:
		mat.metallic = 0.75
		mat.roughness = 0.68
	part.material_override = mat
	parent.add_child(part)
