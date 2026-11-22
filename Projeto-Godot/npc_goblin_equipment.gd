extends RefCounted
## Separa espada, escudo e corpo diretamente das ilhas de triangulos do GLB.
## A textura ORIGINAL e mantida: cada superficie copia as UVs, normais e
## material PBR do arquivo fonte, sem inventar cores ou repintar detalhes.
## Coordenadas medidas em goblin_npc.glb (Sketchfab): espada em +X,
## escudo em -X, ambos constituídos de ilhas desconectadas do corpo.

static func _root(parents: Array[int], n: int) -> int:
	while parents[n]!=n:
		n = parents[n]
	return n

static func _union(parents: Array[int], sizes: Array[int], a: int, b: int) -> void:
	var ra := _root(parents,a)
	var rb := _root(parents,b)
	if ra==rb:
		return
	if sizes[ra]<sizes[rb]:
		var old := ra
		ra = rb
		rb = old
	parents[rb] = ra
	sizes[ra] += sizes[rb]


static func split_mesh(part: MeshInstance3D) -> Array:
	var original := part.mesh
	var output: Array = [ArrayMesh.new(),ArrayMesh.new(),ArrayMesh.new()]
	for surface in range(original.get_surface_count()):
		var source: Array = original.surface_get_arrays(surface)
		var vertices: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = source[Mesh.ARRAY_INDEX]
		if vertices.is_empty():
			continue
		if indices.is_empty():
			indices.resize(vertices.size())
			for i in range(vertices.size()):
				indices[i] = i
		var face_count := indices.size()/3
		var roots: Array[int] = []
		var sizes: Array[int] = []
		roots.resize(face_count)
		sizes.resize(face_count)
		for i in range(face_count):
			roots[i] = i
			sizes[i] = 1
		var first_face: Dictionary = {}
		for i in range(face_count):
			for offset in range(3):
				var vertex: int = indices[i*3+offset]
				if first_face.has(vertex):
					_union(roots,sizes,i,int(first_face[vertex]))
				else:
					first_face[vertex] = i
		var centers: Dictionary = {}
		var face_counts: Dictionary = {}
		for face in range(face_count):
			var id := _root(roots,face)
			var center := (vertices[indices[face*3]]+
				vertices[indices[face*3+1]]+vertices[indices[face*3+2]])/3.0
			centers[id] = (centers.get(id,Vector3.ZERO) as Vector3)+center
			face_counts[id] = int(face_counts.get(id,0))+1
		var class_by_island: Dictionary = {}
		for id in centers.keys():
			var center: Vector3 = centers[id]/float(face_counts[id])
			var group := 0 # corpo
			if center.x > 28.0:
				group = 1 # espada
			elif center.x < -13.0 and center.y > -45.0 and center.z < -4.0:
				group = 2 # escudo
			class_by_island[id] = group
		var groups: Array = [PackedInt32Array(),PackedInt32Array(),PackedInt32Array()]
		for face in range(face_count):
			var group: int = int(class_by_island[_root(roots,face)])
			var destination: PackedInt32Array = groups[group]
			for j in range(3):
				destination.append(indices[face*3+j])
			groups[group] = destination
		for group in range(3):
			var selected: PackedInt32Array = groups[group]
			if selected.is_empty():
				continue
			var copied: Array = _compact_surface(source,selected)
			var mesh := output[group] as ArrayMesh
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,copied)
			var source_material: Material = part.get_active_material(surface)
			if source_material != null:
				# Copia sem editar UV ou albedo: mesma textura do arquivo original.
				var rebuilt: Material = source_material.duplicate(true)
				mesh.surface_set_material(mesh.get_surface_count()-1,rebuilt)
	var pieces: Array = []
	for item in output:
		var mesh := item as ArrayMesh
		pieces.append(mesh if mesh.get_surface_count()>0 else null)
	return pieces


static func _compact_surface(source: Array, selected: PackedInt32Array) -> Array:
	var result: Array = []
	result.resize(Mesh.ARRAY_MAX)
	var old_positions: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var tangents := PackedFloat32Array()
	var colors := PackedColorArray()
	var uv2 := PackedVector2Array()
	var indices := PackedInt32Array()
	var seen: Dictionary = {}
	var has_normals := source[Mesh.ARRAY_NORMAL] is PackedVector3Array
	var has_uv := source[Mesh.ARRAY_TEX_UV] is PackedVector2Array
	var has_tangents := source[Mesh.ARRAY_TANGENT] is PackedFloat32Array
	var has_colors := source[Mesh.ARRAY_COLOR] is PackedColorArray
	var has_uv2 := source[Mesh.ARRAY_TEX_UV2] is PackedVector2Array
	for previous in selected:
		var id: int
		if seen.has(previous):
			id = int(seen[previous])
		else:
			id = positions.size()
			seen[previous] = id
			positions.append(old_positions[previous])
			if has_normals:
				var src_normals: PackedVector3Array = source[Mesh.ARRAY_NORMAL]
				normals.append(src_normals[previous])
			if has_uv:
				var src_uv: PackedVector2Array = source[Mesh.ARRAY_TEX_UV]
				uv.append(src_uv[previous])
			if has_tangents:
				var src_tangents: PackedFloat32Array = source[Mesh.ARRAY_TANGENT]
				for j in range(4):
					tangents.append(src_tangents[previous*4+j])
			if has_colors:
				var src_colors: PackedColorArray = source[Mesh.ARRAY_COLOR]
				colors.append(src_colors[previous])
			if has_uv2:
				var src_uv2: PackedVector2Array = source[Mesh.ARRAY_TEX_UV2]
				uv2.append(src_uv2[previous])
		indices.append(id)
	result[Mesh.ARRAY_VERTEX] = positions
	result[Mesh.ARRAY_INDEX] = indices
	if has_normals: result[Mesh.ARRAY_NORMAL] = normals
	if has_uv: result[Mesh.ARRAY_TEX_UV] = uv
	if has_tangents: result[Mesh.ARRAY_TANGENT] = tangents
	if has_colors: result[Mesh.ARRAY_COLOR] = colors
	if has_uv2: result[Mesh.ARRAY_TEX_UV2] = uv2
	return result


static func attach(body: MeshInstance3D, skeleton: Skeleton3D, asset: ArrayMesh,
		name: String, bone_name: String, collection: Array[Node3D]) -> void:
	if asset == null:
		return
	var bone_index := skeleton.find_bone(bone_name)
	if bone_index<0:
		push_error("Osso de mao nao encontrado: "+bone_name)
		return
	var anchor := BoneAttachment3D.new()
	anchor.name = "Encaixe"+name
	anchor.bone_name = bone_name
	skeleton.add_child(anchor)
	var piece := MeshInstance3D.new()
	piece.name = name
	piece.mesh = asset
	anchor.add_child(piece)
	# Compensa a transformacao do osso na pose neutra: visual original
	# permanece identico. O equipamento segue a mao ao animar.
	piece.transform = skeleton.get_bone_global_rest(bone_index).affine_inverse()*body.transform
	collection.append(piece)
