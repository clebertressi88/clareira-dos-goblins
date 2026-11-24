extends Node3D
## Mochila leve de couro gasto, feita para acompanhar o tronco do Skirmisher.
## A origem coincide com o osso do peito: sem deslocamento vertical artificial.
## Lado de fora = -Z; lado das alcas, encostado no goblin = +Z.

func _mat(hex: String, metal: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(hex)
	result.roughness = 0.94 if metal == 0.0 else 0.53
	result.metallic = metal
	return result

func _mesh(mesh: Mesh, position_value: Vector3, mat: Material, size_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.position = position_value
	piece.scale = size_value
	piece.material_override = mat
	add_child(piece)
	return piece

func _soft(position_value: Vector3, size_value: Vector3, mat: Material) -> void:
	var m := SphereMesh.new()
	m.radius = 0.5
	m.height = 1.0
	m.radial_segments = 20
	m.rings = 12
	_mesh(m,position_value,mat,size_value)

func _bar(position_value: Vector3, size_value: Vector3, mat: Material) -> void:
	var m := BoxMesh.new()
	m.size = size_value
	_mesh(m,position_value,mat)

func _ribbon(points: Array[Vector3], width: float, mat: Material) -> void:
	# Trechos sucessivos criam correias curvas acompanhando os ombros.
	for i in range(points.size()-1):
		var delta: Vector3 = points[i+1]-points[i]
		if delta.length_squared()<0.000001:
			continue
		var segment := BoxMesh.new()
		segment.size = Vector3(width,delta.length(),0.017)
		var piece := _mesh(segment,(points[i+1]+points[i])*0.5,mat)
		piece.quaternion = Quaternion(Vector3.UP,delta.normalized())

func _buckle(at: Vector3, mat: Material, width: float = 0.057) -> void:
	var half := width * 0.5
	_bar(at+Vector3(0,half,0),Vector3(width,0.012,0.009),mat)
	_bar(at-Vector3(0,half,0),Vector3(width,0.012,0.009),mat)
	_bar(at+Vector3(half,0,0),Vector3(0.012,width,0.009),mat)
	_bar(at-Vector3(half,0,0),Vector3(0.012,width,0.009),mat)

func _ready() -> void:
	var leather := _mat("#65452f")
	var leather_lit := _mat("#826044")
	var flap := _mat("#503728")
	var piping := _mat("#443025")
	var seam := _mat("#b09165")
	var buckle := _mat("#847658",0.48)
	var canvas := _mat("#74664b")
	var patch := _mat("#79553e")

	# Corpo estreito e achatado para encaixar na curvatura das costas.
	# A frente do volume (Z positivo) fica quase junto ao osso de fixacao.
	_soft(Vector3(0,-0.075,-0.145),Vector3(0.43,0.53,0.20),leather)
	_soft(Vector3(0,-0.17,-0.146),Vector3(0.41,0.30,0.205),leather_lit)
	# Fundo discreto em vez de uma caixa retangular.
	_soft(Vector3(0,-0.292,-0.17),Vector3(0.39,0.10,0.18),piping)

	# Tampa abaulada e caída na frente, integrada ao corpo.
	_soft(Vector3(0,0.142,-0.175),Vector3(0.435,0.20,0.19),flap)
	_soft(Vector3(0,0.075,-0.258),Vector3(0.405,0.115,0.039),leather_lit)
	# Cinto vertical simples, uma pequena fivela oxidada.
	_ribbon([Vector3(0,0.115,-0.277),Vector3(0,0.005,-0.281),Vector3(0,-0.105,-0.262)],0.051,flap)
	_buckle(Vector3(0,-0.035,-0.300),buckle)
	# Pontos irregulares nas laterais e na aba.
	for i in range(9):
		var x := -0.16+float(i)*0.040
		_bar(Vector3(x,0.04,-0.289),Vector3(0.010,0.007,0.008),seam)
	for side in [-1.0,1.0]:
		for i in range(5):
			_bar(Vector3(side*0.195,-0.225+float(i)*0.067,-0.198),Vector3(0.007,0.014,0.008),seam)

	# Alcas traseiras seguem a silhueta dos ombros ate embaixo.
	# A fita na face +Z torna visivel que o peso esta apoiado no corpo.
	for side in [-1.0,1.0]:
		var x: float = float(side) * 0.145
		_ribbon([
			Vector3(x,0.196,-0.105),
			Vector3(side*0.190,0.205,-0.020),
			Vector3(side*0.215,0.080,0.070),
			Vector3(side*0.190,-0.110,0.070),
			Vector3(side*0.145,-0.271,-0.080)
		],0.055,leather_lit)

	# Apenas um bolso lateral pequeno, sem exagerar o volume.
	_soft(Vector3(-0.194,-0.169,-0.156),Vector3(0.102,0.169,0.117),leather_lit)
	_soft(Vector3(-0.203,-0.095,-0.174),Vector3(0.103,0.057,0.109),flap)
	_buckle(Vector3(-0.214,-0.131,-0.237),buckle,0.028)

	# Rolo de lona preso discretamente no topo.
	var roll := CylinderMesh.new()
	roll.top_radius = 0.051
	roll.bottom_radius = 0.052
	roll.height = 0.28
	roll.radial_segments = 14
	var cloth_roll := _mesh(roll,Vector3(0,0.228,-0.153),canvas)
	cloth_roll.rotation.z = PI*0.5
	_ribbon([Vector3(-0.085,0.264,-0.177),Vector3(-0.085,0.185,-0.176)],0.024,flap)
	_ribbon([Vector3(0.085,0.264,-0.177),Vector3(0.085,0.185,-0.176)],0.024,flap)

	# Remendo fino para aspecto artesanal sem poluir a silhueta.
	_bar(Vector3(0.113,-0.183,-0.247),Vector3(0.080,0.066,0.010),patch)
	for i in range(3):
		_bar(Vector3(0.085+float(i)*0.027,-0.143,-0.255),Vector3(0.008,0.009,0.008),seam)
