extends RefCounted
# Modelo 3D de picareta medieval com cabo de madeira e cabeca entalhada.
static func build(parent: Node3D, stone: bool) -> void:
	var handle := CylinderMesh.new()
	handle.top_radius = 0.033
	handle.bottom_radius = 0.046
	handle.height = 0.78
	handle.radial_segments = 10
	_part(parent,handle,Vector3.ZERO,Vector3.ONE,Color("#775032"))
	var grip := CylinderMesh.new()
	grip.top_radius = 0.043
	grip.bottom_radius = 0.043
	grip.height = 0.13
	grip.radial_segments = 10
	_part(parent,grip,Vector3(0,-0.24,0),Vector3.ONE,Color("#453326"))
	var head_color := Color("#858784") if stone else Color("#a47747")
	var head := BoxMesh.new()
	head.size = Vector3(0.44,0.085,0.11)
	_part(parent,head,Vector3(0,0.27,0),Vector3.ONE,head_color)
	for side in [-1.0,1.0]:
		var point := CylinderMesh.new()
		point.top_radius = 0.0
		point.bottom_radius = 0.055
		point.height = 0.23
		point.radial_segments = 7
		var tip := _part(parent,point,Vector3(side*0.32,0.27,0),Vector3.ONE,head_color)
		tip.rotation.z = -side*PI/2.0
	for side in [-1.0,1.0]:
		var binding := BoxMesh.new()
		binding.size = Vector3(0.036,0.115,0.13)
		_part(parent,binding,Vector3(side*0.09,0.27,0),Vector3.ONE,Color("#5a4532"))

static func _part(parent: Node3D, mesh: Mesh, pos: Vector3, scale_vec: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	instance.scale = scale_vec
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	instance.material_override = mat
	parent.add_child(instance)
	return instance
