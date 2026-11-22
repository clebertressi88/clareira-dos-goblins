extends RefCounted
## Pesos de pele por componente anatomico RIGIDO, em vez de interpolacao
## por altura. Cada ilha conexa da malha recebe 100% de um osso.
## Isso impede esticar/corromper olhos, ombreiras, botas e dedos.
## Coordenadas calibradas para res://modelos/goblin_npc.glb.

static func _root(parents: Array[int], idx: int) -> int:
	while parents[idx]!=idx:
		idx=parents[idx]
	return idx

static func _link(parents: Array[int], sizes: Array[int], a: int, b: int) -> void:
	var ra := _root(parents,a)
	var rb := _root(parents,b)
	if ra==rb:
		return
	if sizes[ra]<sizes[rb]:
		var temp := ra
		ra=rb
		rb=temp
	parents[rb]=ra
	sizes[ra]+=sizes[rb]


static func _anatomical_bone(c: Vector3, size: int) -> int:
	# Eixo Y e negativo no arquivo antes da transformacao Sketchfab.
	# Cranio/olhos/orelhas (uma ilha grande) seguem somente o pescoco.
	if c.y < -44.0 and c.x < 16.0:
		return 2
	# Braço direito estendido em direcao a espada.
	if c.y > -46.0 and c.y < -18.0 and c.x > 12.0:
		return 6 if c.x > 29.0 else 5
	# Braço esquerdo curvado atras do escudo.
	if c.y > -44.0 and c.y < -18.0 and (c.x < -12.0 or
			(size > 80 and c.x < -7.0 and c.z < -9.0)):
		return 4 if c.x < -23.0 else 3
	# Botas/canelas. Sao objetos realmente separados no GLB.
	if c.y > -19.0:
		if c.x < 0.0:
			if c.y > -9.0: return 11
			if c.y > -17.0: return 8
			return 7
		if c.y > -9.0: return 12
		if c.y > -17.0: return 10
		return 9
	# Cinto/calcas e torso.
	if c.y > -28.0 and absf(c.x) < 12.0:
		return 0
	if c.y <= -28.0 and absf(c.x) < 14.0:
		return 1
	return 0


static func build(original: Mesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	for surface in range(original.get_surface_count()):
		if original.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays: Array = original.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if vertices.is_empty():
			continue
		var n := vertices.size()
		var parents: Array[int] = []
		var sizes: Array[int] = []
		parents.resize(n)
		sizes.resize(n)
		for i in range(n):
			parents[i]=i
			sizes[i]=1
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			indices.resize(n)
			for i in range(n):
				indices[i]=i
		for i in range(0,indices.size()-2,3):
			_link(parents,sizes,indices[i],indices[i+1])
			_link(parents,sizes,indices[i],indices[i+2])
		# Costuras de UV duplicam vertices: unem-se apenas as posicoes
		# realmente coincidentes para que uma bota nunca rache pela costura.
		var positions: Dictionary = {}
		for i in range(n):
			var v: Vector3 = vertices[i]
			var coord := Vector3i(roundi(v.x*1000.0),roundi(v.y*1000.0),roundi(v.z*1000.0))
			if positions.has(coord):
				_link(parents,sizes,i,int(positions[coord]))
			else:
				positions[coord]=i
		var component_sum: Dictionary = {}
		var component_count: Dictionary = {}
		for i in range(n):
			var root_index := _root(parents,i)
			component_sum[root_index]=(component_sum.get(root_index,Vector3.ZERO) as Vector3)+vertices[i]
			component_count[root_index]=int(component_count.get(root_index,0))+1
		var component_bone: Dictionary = {}
		for root_index in component_sum.keys():
			var count: int = int(component_count[root_index])
			var center: Vector3 = component_sum[root_index]/float(count)
			component_bone[root_index]=_anatomical_bone(center,count)
		var bone_ids := PackedInt32Array()
		var weights := PackedFloat32Array()
		bone_ids.resize(n*4)
		weights.resize(n*4)
		for i in range(n):
			var assigned: int = int(component_bone[_root(parents,i)])
			bone_ids[i*4]=assigned
			bone_ids[i*4+1]=0
			bone_ids[i*4+2]=0
			bone_ids[i*4+3]=0
			weights[i*4]=1.0
			weights[i*4+1]=0.0
			weights[i*4+2]=0.0
			weights[i*4+3]=0.0
		arrays[Mesh.ARRAY_BONES]=bone_ids
		arrays[Mesh.ARRAY_WEIGHTS]=weights
		# Reusa sem alteracao UVs, faces, normais e tangentes da textura.
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var material := original.surface_get_material(surface)
		if material != null:
			result.surface_set_material(result.get_surface_count()-1,material)
	return result
