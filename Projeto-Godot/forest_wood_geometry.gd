extends RefCounted
## Geometria de madeira compartilhada por troncos, raizes e galhos.
## As secoes sao afuniladas e penetram levemente no tronco para ocultar juncoes.
## Sem colisao adicional; somente o colisor existente do tronco e usado.

static func tapered(parent: Node3D, start: Vector3, finish: Vector3, base_radius: float, tip_radius: float, bark: Material, segments: int = 9) -> MeshInstance3D:
	var delta := finish - start
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = base_radius
	mesh.top_radius = tip_radius
	mesh.height = maxf(delta.length(),0.01)
	mesh.radial_segments = segments
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = bark
	part.position = (start + finish) * 0.5
	part.quaternion = Quaternion(Vector3.UP,delta.normalized()) if delta.length_squared()>0.000001 else Quaternion.IDENTITY
	parent.add_child(part)
	return part

static func make_trunk(parent: Node3D, bark: Material, adult: bool) -> MeshInstance3D:
	# Adulto e toco partilham o mesmo perfil de base para nao criar degrau.
	var flare := tapered(parent,Vector3.ZERO,Vector3.UP*0.44,0.355,0.225,bark,12)
	flare.name = "TroncoToco" if not adult else "BaseAlargada"
	if adult:
		var upper := tapered(parent,Vector3.UP*0.405,Vector3.UP*2.20,0.230,0.205,bark,12)
		upper.name = "TroncoPrincipal"
	return flare

static func make_roots(parent: Node3D, bark: Material, tree_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(tree_id+"-raizes"))
	for i in range(5):
		var angle := TAU*float(i)/5.0 + rng.randf_range(-0.23,0.23)
		var direction := Vector3(cos(angle),0,sin(angle))
		var side := Vector3(-direction.z,0,direction.x)
		var total := rng.randf_range(0.60,0.85)
		# O primeiro terco sai de dentro do pe alargado, nao da face externa.
		var start := direction*0.09 + Vector3.UP*0.205
		var elbow := direction*(total*0.52) + side*rng.randf_range(-0.07,0.07) + Vector3.UP*0.068
		var tip := direction*total + side*rng.randf_range(-0.08,0.08) + Vector3.UP*0.02
		tapered(parent,start,elbow,0.145,0.091,bark,8)
		tapered(parent,elbow-direction*0.025,tip,0.094,0.019,bark,7)

static func make_branch(parent: Node3D, start: Vector3, tip: Vector3, radius: float, bark: Material) -> void:
	var delta := tip-start
	if delta.length_squared() < 0.001:
		return
	# A raiz do galho fica embutida no tronco e engrossada na origem.
	var mid := start+delta*0.43+Vector3.UP*0.028
	tapered(parent,start,mid,radius*1.26,radius*0.76,bark,8)
	tapered(parent,mid-delta.normalized()*0.025,tip,radius*0.79,radius*0.28,bark,7)
