extends RefCounted
## Cortes de carne crua em vez de esferas: bisteca de lobo e porcao de coelho.
## O modelo e apenas visual; ambos continuam sendo o item Carne no inventario.

static func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.78
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

static func _mesh(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3 = Vector3.ZERO) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = pos
	parent.add_child(part)

static func _strand(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var d: Vector3 = b - a
	if d.length_squared() < 0.000001:
		return
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = d.length()
	mesh.radial_segments = 7
	var segment := MeshInstance3D.new()
	segment.mesh = mesh
	segment.material_override = material
	segment.position = (a+b) * 0.5
	segment.quaternion = Quaternion(Vector3.UP,d.normalized())
	parent.add_child(segment)

static func _outline_piece(parent: Node3D, width: float, depth: float, thickness: float, material: Material) -> void:
	# Superficie e laterais trianguladas, com silhueta de corte irregular.
	var shape := PackedVector2Array([
		Vector2(-0.87,-0.44),Vector2(-0.63,-0.83),Vector2(-0.18,-0.97),
		Vector2(0.35,-0.89),Vector2(0.83,-0.61),Vector2(1.00,-0.12),
		Vector2(0.83,0.45),Vector2(0.43,0.87),Vector2(-0.10,0.94),
		Vector2(-0.63,0.72),Vector2(-0.97,0.19)
	])
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(shape.size()):
		var j: int = (i + 1) % shape.size()
		var pa := Vector3(shape[i].x * width, thickness, shape[i].y * depth)
		var pb := Vector3(shape[j].x * width, thickness, shape[j].y * depth)
		var qa := Vector3(pa.x,0.017,pa.z)
		var qb := Vector3(pb.x,0.017,pb.z)
		for v in [Vector3(0.0,thickness + 0.007,0.0),pa,pb,pa,qa,qb,pa,qb,pb]:
			mesh.set_uv(Vector2(v.x + 0.5,v.z + 0.5))
			mesh.add_vertex(v)
	mesh.generate_normals()
	_mesh(parent,mesh.commit(),material)

static func build(parent: Node3D, from_rabbit: bool = false) -> void:
	var meat := _material(Color("#ae4c4b") if from_rabbit else Color("#963332"))
	var inner := _material(Color("#c76763") if from_rabbit else Color("#bf5550"))
	var fat := _material(Color("#f0d2b0") if from_rabbit else Color("#e2b89b"))
	var grain := _material(Color("#762e32") if from_rabbit else Color("#72252a"))
	var bone := _material(Color("#e9dac0"))
	var width: float = 0.16 if from_rabbit else 0.24
	var depth: float = 0.115 if from_rabbit else 0.18
	var thick: float = 0.065 if from_rabbit else 0.095
	_outline_piece(parent,width,depth,thick,meat)
	# Varios pequenos lobulos de carne moldados, evitando visual de bola perfeita.
	for i in range(3):
		var piece := SphereMesh.new()
		piece.radial_segments = 12
		piece.rings = 7
		var part := MeshInstance3D.new()
		part.mesh = piece
		part.material_override = inner
		part.position = Vector3((-0.35 + 0.35 * float(i)) * width,thick + 0.009,(-0.3 + 0.32 * float(i)) * depth)
		part.scale = Vector3(width * 0.27,0.017,depth * 0.31)
		parent.add_child(part)
	# Gordura nas bordas e fibras musculares da parte superior.
	# Dois veios irregulares adicionais em ambos os cortes: deixam a
	# superficie menos lisa e preservam a silhueta de carne (sem esfera).
	_strand(parent,Vector3(-0.72*width,thick+0.012,0.43*depth),
		Vector3(-0.19*width,thick+0.018,0.63*depth),
		0.003 if from_rabbit else 0.004,inner)
	_strand(parent,Vector3(0.18*width,thick+0.015,-0.63*depth),
		Vector3(0.67*width,thick+0.014,-0.33*depth),
		0.003 if from_rabbit else 0.004,grain)
	var rim: Array[Vector3] = [
		Vector3(-0.85*width,thick + 0.008,-0.42*depth),
		Vector3(-0.60*width,thick + 0.008,-0.81*depth),
		Vector3(-0.16*width,thick + 0.008,-0.94*depth),
		Vector3(0.35*width,thick + 0.008,-0.87*depth)
	]
	for i in range(rim.size()-1):
		_strand(parent,rim[i],rim[i+1],0.008 if from_rabbit else 0.011,fat)
	for i in range(4):
		var offset: float = float(i) * 0.21 - 0.33
		_strand(parent,Vector3(-0.52*width,thick+0.022,offset*depth),
			Vector3(0.47*width,thick+0.022,(offset+0.22)*depth),
			0.003 if from_rabbit else 0.004,grain)
	if from_rabbit:
		# Porcao menor: dois pedacos de coelho, separados por osso claro.
		var small := SphereMesh.new()
		small.radial_segments = 10
		small.rings = 6
		var fillet := MeshInstance3D.new()
		fillet.mesh = small
		fillet.material_override = meat
		fillet.position = Vector3(width*0.77,0.038,depth*0.34)
		fillet.scale = Vector3(0.082,0.038,0.054)
		parent.add_child(fillet)
		_strand(parent,Vector3(-0.02,thick+0.014,0.015),
			Vector3(0.09,thick+0.024,0.038),0.009,bone)
	else:
		# Corte mais espesso de lobo, com veios claros de gordura.
		_strand(parent,Vector3(-width*0.25,thick+0.024,depth*0.28),
			Vector3(width*0.47,thick+0.024,depth*0.38),0.007,fat)
		_strand(parent,Vector3(-width*0.35,thick+0.024,-depth*0.15),
			Vector3(width*0.19,thick+0.024,-depth*0.27),0.005,fat)
