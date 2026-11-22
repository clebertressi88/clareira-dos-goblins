extends RefCounted
## Encaixe e verificacao de paredes.
## Chamado pelos wrappers em main.gd para preservar o comportamento do jogo.

static func find_wall_snap(point: Vector3, yaw: float, placed: Array, wall_size: float) -> Vector3:
	# Novo segmento encaixa uma ponta à ponta da parede existente mais próxima.
	# Funciona tanto para paredes retas quanto para cantos em L/U.
	var new_axis := Basis(Vector3.UP,yaw).x.normalized()
	var best := point
	var best_distance := wall_size*.85
	for entry in placed:
		if entry.get("kind","") not in ["wood_wall","wood_doorway","wood_window"]:
			continue
		var p: Array = entry["p"]
		var old_position := Vector3(float(p[0]),float(p[1]),float(p[2]))
		var old_yaw := float(entry.get("r",0.0))
		var old_axis := Basis(Vector3.UP,old_yaw).x.normalized()
		for old_sign in [-1.0,1.0]:
			for new_sign in [-1.0,1.0]:
				var candidate: Vector3 = old_position+old_axis*(old_sign*wall_size*.5)-new_axis*(new_sign*wall_size*.5)
				var distance := Vector2(point.x-candidate.x,point.z-candidate.z).length()
				if distance<best_distance:
					best_distance = distance
					best = candidate
	return best

static func wall_intersects_other_wall(point: Vector3, yaw: float, placed: Array, wall_size: float) -> bool:
	# Impede duas paredes no mesmo lugar, mas permite os cantos de 90 graus.
	var axis := Vector2(cos(yaw),-sin(yaw))
	for entry in placed:
		if entry.get("kind","") not in ["wood_wall","wood_doorway","wood_window"]:
			continue
		var p: Array = entry["p"]
		var old := Vector2(float(p[0]),float(p[2]))
		var this := Vector2(point.x,point.z)
		var other_yaw := float(entry.get("r",0.0))
		var old_axis := Vector2(cos(other_yaw),-sin(other_yaw))
		var delta := this-old
		var aligned := absf(axis.dot(old_axis))>.95
		if aligned:
			if absf(delta.dot(axis))<wall_size-.12 and absf(delta.cross(axis))<.17:
				return true
		else:
			# Cruzes no meio da parede são bloqueados; cantos no final são permitidos.
			if absf(delta.dot(old_axis))<wall_size*.5-.14 and absf(delta.dot(axis))<wall_size*.5-.14:
				return true
	return false
