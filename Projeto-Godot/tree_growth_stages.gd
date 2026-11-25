extends RefCounted
## Dois modelos de crescimento independentes, com tronco marrom e folhas recortadas.
## A origem de ambos e a base do caule, posicionada no topo do toco (Y=.52).
const FOLIAGE := preload("res://forest_tree_visual.gd")
const WOOD := preload("res://forest_wood_geometry.gd")

static func make_bud(root: Node3D, tree_id: String) -> void:
	# Broto curto: caule fino marrom-esverdeado e folhas individuais recortadas.
	# Origem local = ponto de corte do toco, sem escalas que criem haste gigante.
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(tree_id + "-broto"))
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color("#6d7739")
	stem_mat.roughness = 1.0
	WOOD.tapered(root,Vector3.ZERO,Vector3(0,0.19,0),0.019,0.009,stem_mat,6)
	var cards: Array[Transform3D] = []
	for i in range(3):
		var a := TAU*float(i)/3.0 + rng.randf_range(-0.2,0.2)
		var radius := 0.065 if i<2 else 0.025
		var center := Vector3(cos(a)*radius,0.14+float(i)*0.028,sin(a)*radius)
		_add_foliage(cards,center,0.16,a,rng)
	FOLIAGE._add_leaf_batch(root,cards)

static func make_stage(root: Node3D, bark: Material, tree_id: String, young: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(tree_id + ("-jovem" if young else "-muda")))
	var height := 1.37 if young else 0.67
	var radius := 0.115 if young else 0.060
	WOOD.tapered(root,Vector3.ZERO,Vector3.UP*height,radius*1.25,radius*0.75,bark,8)
	var crown_y := height + (0.09 if young else 0.01)
	var spread := 0.50 if young else 0.22
	var count := 11 if young else 5
	var cards: Array[Transform3D] = []
	for i in range(count):
		var angle := TAU*float(i)/float(count) + rng.randf_range(-0.25,0.25)
		var horizontal := rng.randf_range(spread*0.35,spread)
		var y := crown_y+rng.randf_range(-0.27 if young else -0.12,0.31 if young else 0.17)
		var end := Vector3(cos(angle)*horizontal,y,sin(angle)*horizontal)
		if i < (6 if young else 3):
			WOOD.make_branch(root,Vector3(0.0,height*0.67,0.0),end,0.038 if young else 0.019,bark)
		var cluster_size := rng.randf_range(0.39,0.58) if young else rng.randf_range(0.22,0.34)
		_add_foliage(cards,end,cluster_size,angle,rng)
	# Preenchimento do centro; sem as antigas bolas verdes.
	_add_foliage(cards,Vector3(0,crown_y+0.16,0),0.58 if young else 0.31,0.4,rng)
	FOLIAGE._add_leaf_batch(root,cards)

static func _add_foliage(cards: Array[Transform3D], pos: Vector3, extent: float, angle: float, rng: RandomNumberGenerator) -> void:
	for side in range(2):
		var rotation := Vector3(rng.randf_range(-0.2,0.2),angle+float(side)*PI*0.5,0)
		var basis := Basis.from_euler(rotation).scaled_local(Vector3(extent*1.35,extent,1))
		cards.append(Transform3D(basis,pos))
