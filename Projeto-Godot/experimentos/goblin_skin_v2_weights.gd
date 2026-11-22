extends RefCounted
## EXPERIMENTO - skin de goblin v2. Nunca substitui a skin usada no jogo.
## Preserve todos os vertices, indices, UVs, normais, materiais e textura do GLB.
## Cabeca, botas e placas de armadura ficam rigidas. Somente o corpo organico
## recebe transicoes curtas e controladas nos cotovelos e joelhos.

static func _root(parents: Array[int], at: int) -> int:
	while parents[at]!=at:
		parents[at]=parents[parents[at]]
		at=parents[at]
	return at


static func _union(parents: Array[int], sizes: Array[int], a: int, b: int) -> void:
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


static func _region(c: Vector3, count: int) -> String:
	# Coordenadas no espaco local do arquivo original: +Y aponta para os pes.
	if c.y < -44.0:
		return "head"
	if c.y > -20.5 and absf(c.x)<19.0:
		return "leg_l" if c.x<0.0 else "leg_r"
	if c.y > -47.0 and c.y < -16.0:
		if c.x > 11.0:
			return "arm_r"
		if c.x < -9.5 and (c.z < -6.0 or count>150):
			return "arm_l"
	if c.y < -31.0:
		return "chest"
	return "hips"


static func _blend(v: Vector3, start: Vector3, end: Vector3) -> float:
	var direction := end-start
	var projection := (v-start).dot(direction)/maxf(direction.length_squared(),0.01)
	return smoothstep(.38,.63,projection)


static func _assignment(v: Vector3, center: Vector3, count: int, region: String) -> Vector3:
	# Retorna [ossoA, ossoB, pesoB]. PesoA=1-pesoB; total sempre 1.
	match region:
		"head":
			return Vector3(2,2,0)
		"chest":
			return Vector3(1,1,0)
		"hips":
			return Vector3(0,0,0)
		"arm_r":
			if count<130:
				var which := 6 if center.x>25.0 else 5
				return Vector3(which,which,0)
			var t := _blend(v,Vector3(13,-42,1),Vector3(34,-25,-1))
			return Vector3(5,6,t)
		"arm_l":
			if count<130:
				var which := 4 if center.x < -20.0 else 3
				return Vector3(which,which,0)
			var t := _blend(v,Vector3(-12,-39,-12),Vector3(-26,-23,-18))
			return Vector3(3,4,t)
		"leg_l":
			if center.y > -9.5:
				return Vector3(11,11,0)
			if count<100:
				var which := 8 if center.y > -16.0 else 7
				return Vector3(which,which,0)
			var t := _blend(v,Vector3(-7,-20,6),Vector3(-8,-8,7))
			return Vector3(7,8,t)
		"leg_r":
			if center.y > -9.5:
				return Vector3(12,12,0)
			if count<100:
				var which := 10 if center.y > -16.0 else 9
				return Vector3(which,which,0)
			var t := _blend(v,Vector3(8,-20,-16),Vector3(9,-8,-18))
			return Vector3(9,10,t)
	return Vector3(0,0,0)


static func build(original: Mesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	for surface in range(original.get_surface_count()):
		if original.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays: Array = original.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var n := vertices.size()
		if n==0:
			continue
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
			_union(parents,sizes,indices[i],indices[i+1])
			_union(parents,sizes,indices[i],indices[i+2])
		# Conservar ilhas por posicao, mesmo nos vertices duplicados pelas UVs.
		var duplicates: Dictionary = {}
		for i in range(n):
			var v: Vector3=vertices[i]
			var key:=Vector3i(roundi(v.x*1000),roundi(v.y*1000),roundi(v.z*1000))
			if duplicates.has(key):
				_union(parents,sizes,i,int(duplicates[key]))
			else:
				duplicates[key]=i
		var sums: Dictionary = {}
		var counts: Dictionary = {}
		for i in range(n):
			var root_id := _root(parents,i)
			sums[root_id]=(sums.get(root_id,Vector3.ZERO) as Vector3)+vertices[i]
			counts[root_id]=int(counts.get(root_id,0))+1
		var labels: Dictionary = {}
		for root_id in sums.keys():
			var count: int = int(counts[root_id])
			var center: Vector3 = sums[root_id]/float(count)
			labels[root_id]={"center":center,"count":count,"region":_region(center,count)}
		var ids := PackedInt32Array()
		var weights := PackedFloat32Array()
		ids.resize(n*4)
		weights.resize(n*4)
		for i in range(n):
			var component: Dictionary = labels[_root(parents,i)]
			var assignment := _assignment(vertices[i],component["center"],
				int(component["count"]),str(component["region"]))
			var t := clampf(assignment.z,0.0,1.0)
			var offset := i*4
			ids[offset]=int(assignment.x)
			ids[offset+1]=int(assignment.y)
			ids[offset+2]=0
			ids[offset+3]=0
			weights[offset]=1.0-t
			weights[offset+1]=t
			weights[offset+2]=0.0
			weights[offset+3]=0.0
		arrays[Mesh.ARRAY_BONES]=ids
		arrays[Mesh.ARRAY_WEIGHTS]=weights
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var material := original.surface_get_material(surface)
		if material!=null:
			result.surface_set_material(result.get_surface_count()-1,material)
	return result
