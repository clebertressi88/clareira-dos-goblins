extends RefCounted
## Helpers para malhas e colisores.
## Chamado pelos wrappers em main.gd para preservar o comportamento do jogo.

static func mesh_part(parent: Node3D, geometry: Mesh, pos: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = geometry
	part.material_override = mat
	part.position = pos
	part.scale = scale_value
	parent.add_child(part)
	return part

static func collider(body: CollisionObject3D, size: Vector3, offset: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = offset
	body.add_child(col)
