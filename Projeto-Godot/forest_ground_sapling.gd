extends RefCounted
## Muda coletavel rasteira: galho torto apoiado no solo com folhas baixas.
## Geometria leve para varias instancias, sem texturas externas.
const WOOD := preload("res://forest_wood_geometry.gd")

static func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	return mat

static func _leaf(parent: Node3D, position: Vector3, axis: Vector3, length: float, mat: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.10
	mesh.height = 0.20
	mesh.radial_segments = 6
	mesh.rings = 3
	var blade := MeshInstance3D.new()
	blade.name = "Folha"
	blade.mesh = mesh
	blade.material_override = mat
	blade.position = position
	blade.scale = Vector3(0.55,length / 0.20,0.22)
	blade.quaternion = Quaternion(Vector3.UP,axis.normalized())
	parent.add_child(blade)

static func build(root: Node3D, seed: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(seed + "-muda-rasteira"))
	var bark := _material(Color("#745037"))
	var leaf_green := _material(Color("#719e48"))
	var leaf_dark := _material(Color("#456e38"))
	var dry_leaf := _material(Color("#a17a4a"))
	var moss := _material(Color("#557a37"))
	# Dois segmentos de galho, apoiados no chao (sem haste vertical).
	var a := Vector3(-0.29,0.055,-0.06)
	var b := Vector3(-0.04,0.085,0.035)
	var c := Vector3(0.28,0.057,0.09)
	WOOD.tapered(root,a,b,0.039,0.030,bark,6)
	WOOD.tapered(root,b,c,0.030,0.012,bark,6)
	# Brotinhos curtos, inclinados para os lados e misturados as folhas secas.
	for i in range(4):
		var t := (float(i)+0.5)/4.0
		var center := a.lerp(c,t)
		var side := -1.0 if i%2==0 else 1.0
		var tip := center+Vector3(rng.randf_range(-0.035,0.035),rng.randf_range(0.09,0.17),side*rng.randf_range(0.10,0.19))
		WOOD.tapered(root,center,tip,0.011,0.005,bark,5)
		var direction := (tip-center).normalized()
		_leaf(root,tip,direction,0.16 if i<2 else 0.13,leaf_green if i%2==0 else leaf_dark)
	# Folhas secas deitadas ao redor da muda: parte da malha, nao do terreno.
	for i in range(5):
		var angle := TAU*float(i)/5.0+rng.randf_range(-0.18,0.18)
		var rad := rng.randf_range(0.24,0.38)
		var pos := Vector3(cos(angle)*rad,0.024,sin(angle)*rad)
		_leaf(root,pos,Vector3(cos(angle),0.08,sin(angle)),rng.randf_range(0.13,0.21),dry_leaf)
	# Musgo rente ao chao, com poucas massas discretas.
	for i in range(3):
		var cushion := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.12
		mesh.height = 0.20
		mesh.radial_segments = 7
		mesh.rings = 3
		cushion.mesh = mesh
		cushion.material_override = moss
		cushion.position = Vector3(-0.10+float(i)*0.12,0.019,0.12+float(i%2)*0.035)
		cushion.scale = Vector3(1.0,0.22,0.65)
		root.add_child(cushion)
