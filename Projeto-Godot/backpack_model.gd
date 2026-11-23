extends Node3D
## Mochila medieval de couro para o protagonista. Modelo procedural independente:
## corpo abaulado, tampa arredondada, pespontos, bolsos, fivelas e correias.
## Frente da mochila aponta para -Z, mantendo a orientacao do modelo anterior.

func _material(color: Color, roughness: float = 0.92, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metal
	return m

func _part(shape: Mesh, at: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = shape
	n.position = at
	n.scale = scale_value
	n.material_override = mat
	add_child(n)
	return n

func _rounded(at: Vector3, radius: float, size: Vector3, mat: Material) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	_part(sphere,at,size,mat)

func _box(at: Vector3, size: Vector3, mat: Material) -> void:
	var cube := BoxMesh.new()
	cube.size = size
	_part(cube,at,Vector3.ONE,mat)

func _strap(from_pos: Vector3, to_pos: Vector3, thickness: float, mat: Material) -> void:
	var segment := to_pos-from_pos
	var cube := BoxMesh.new()
	cube.size = Vector3(thickness,segment.length(),thickness*.55)
	var item := _part(cube,(from_pos+to_pos)*.5,Vector3.ONE,mat)
	item.quaternion = Quaternion(Vector3.UP,segment.normalized())

func _ring(center: Vector3, half_w: float, half_h: float, mat: Material) -> void:
	var thick := 0.015
	_box(center+Vector3(0,half_h,0),Vector3(half_w*2+thick,thick,thick),mat)
	_box(center-Vector3(0,half_h,0),Vector3(half_w*2+thick,thick,thick),mat)
	_box(center+Vector3(half_w,0,0),Vector3(thick,half_h*2,thick),mat)
	_box(center-Vector3(half_w,0,0),Vector3(thick,half_h*2,thick),mat)

func _ready() -> void:
	var leather := _material(Color("#815233"))
	var leather_light := _material(Color("#a47649"))
	var flap := _material(Color("#704229"))
	var pocket := _material(Color("#885631"))
	var edging := _material(Color("#4b3021"))
	var stitches := _material(Color("#d0ab74"))
	var brass := _material(Color("#c19a4a"),0.36,0.62)
	var cloth := _material(Color("#a99770"))
	var patch := _material(Color("#59352b"))

	# Corpo volumoso, com fundo e topo arredondados em vez de uma caixa.
	_rounded(Vector3(0,.95,-.34),.5,Vector3(.59,.65,.33),leather)
	_rounded(Vector3(0,.75,-.36),.40,Vector3(.68,.36,.39),leather)
	# Faixa inferior de reforco.
	_rounded(Vector3(0,.69,-.505),.27,Vector3(.83,.15,.19),edging)

	# Tampa externa abaulada com acabamento escuro.
	_rounded(Vector3(0,1.19,-.51),.43,Vector3(.71,.28,.20),flap)
	_rounded(Vector3(0,1.17,-.615),.40,Vector3(.71,.24,.055),leather_light)
	# Borda costurada da aba; pontos individuais visiveis de perto.
	for i in range(15):
		var x := -.275+float(i)*.039
		var arc := sqrt(maxf(0.0,1.0-pow(x/.325,2.0)))
		_box(Vector3(x,1.098-.045*arc,-.650),Vector3(.012,.008,.008),stitches)

	# Faixa central de couro para fechamento, terminando em fivela de latao.
	_box(Vector3(0,.99,-.64),Vector3(.080,.37,.034),flap)
	_ring(Vector3(0,.989,-.669),.051,.060,brass)
	_box(Vector3(0,.974,-.683),Vector3(.012,.056,.013),brass)
	_box(Vector3(0,.85,-.647),Vector3(.065,.12,.034),leather_light)
	# Presilhas na parte superior e ombros.
	for side in [-1.0,1.0]:
		var x: float = float(side) * 0.235
		_box(Vector3(x,1.38,-.26),Vector3(.083,.045,.20),flap)
		_strap(Vector3(x,.76,-.10),Vector3(x,1.34,-.14),.071,leather_light)
		# Bolso lateral arredondado e sua pequena tampa.
		_rounded(Vector3(side*.326,.85,-.44),.24,Vector3(.48,.46,.51),pocket)
		_rounded(Vector3(side*.327,.99,-.52),.22,Vector3(.48,.20,.34),flap)
		_box(Vector3(side*.333,.87,-.665),Vector3(.043,.15,.029),leather_light)
		_ring(Vector3(side*.333,.87,-.688),.023,.031,brass)
		for j in range(5):
			var y := .71+float(j)*.060
			_box(Vector3(side*.475,y,-.555),Vector3(.009,.013,.012),stitches)
	# Patch gasto e emendas de couro.
	_box(Vector3(-.15,.755,-.678),Vector3(.15,.09,.012),patch)
	for i in range(4):
		_box(Vector3(-.215+float(i)*.039,.80,-.686),Vector3(.012,.014,.012),stitches)
	# Rolo de tecido preso a lateral direita.
	var roll := CylinderMesh.new()
	roll.top_radius = .066
	roll.bottom_radius = .066
	roll.height = .27
	roll.radial_segments = 14
	_part(roll,Vector3(.40,1.04,-.30),Vector3.ONE,cloth)
	_box(Vector3(.40,1.05,-.369),Vector3(.13,.050,.036),flap)
	# Alcas de ombro sao parte do modelo, nao do inventario.
