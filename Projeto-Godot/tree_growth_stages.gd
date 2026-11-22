extends RefCounted
## Dois modelos de crescimento independentes, com tronco marrom e folhas recortadas.
## A origem de ambos e a base do caule, posicionada no topo do toco (Y=.52).
const FOLIAGE := preload("res://forest_tree_visual.gd")

static func make_stage(root: Node3D, bark: Material, tree_id: String, young: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(tree_id + ("-jovem" if young else "-muda")))
	var height := 1.37 if young else 0.67
	var radius := 0.115 if young else 0.060
	_add_wood(root,Vector3.ZERO,Vector3.UP*height,radius,bark)
	var crown_y := height + (0.09 if young else 0.01)
	var spread := 0.50 if young else 0.22
	var count := 11 if young else 5
	for i in range(count):
		var angle := TAU*float(i)/float(count) + rng.randf_range(-0.25,0.25)
		var horizontal := rng.randf_range(spread*0.35,spread)
		var y := crown_y+rng.randf_range(-0.27 if young else -0.12,0.31 if young else 0.17)
		var end := Vector3(cos(angle)*horizontal,y,sin(angle)*horizontal)
		if i < (6 if young else 3):
			_add_wood(root,Vector3(0.0,height*0.67,0.0),end,0.038 if young else 0.019,bark)
		var cluster_size := rng.randf_range(0.39,0.58) if young else rng.randf_range(0.22,0.34)
		_add_foliage(root,end,cluster_size,angle,rng)
	# Preenchimento do centro; sem as antigas bolas verdes.
	_add_foliage(root,Vector3(0,crown_y+0.16,0),0.58 if young else 0.31,0.4,rng)

static func _add_wood(parent: Node3D, start: Vector3, tip: Vector3, radius: float, bark: Material) -> void:
	var delta := tip-start
	if delta.length_squared() < 0.0001:
		return
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius*0.72
	mesh.height = delta.length()
	mesh.radial_segments = 7
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = bark
	part.position = (start+tip)*0.5
	part.quaternion = Quaternion(Vector3.UP,delta.normalized())
	parent.add_child(part)

static func _add_foliage(parent: Node3D, pos: Vector3, extent: float, angle: float, rng: RandomNumberGenerator) -> void:
	for side in range(2):
		var leaves := MeshInstance3D.new()
		leaves.mesh = FOLIAGE._leaf_mesh()
		leaves.material_override = FOLIAGE._leaf_material()
		leaves.position = pos
		leaves.rotation = Vector3(rng.randf_range(-0.2,0.2),angle+float(side)*PI*0.5,0)
		leaves.scale = Vector3(extent*1.35,extent,1)
		parent.add_child(leaves)
