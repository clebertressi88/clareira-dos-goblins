extends RefCounted
# Abrigo inicial procedural: a porta e as janelas nao possuem colisao.
static func piece(game: Node3D, body: StaticBody3D, position: Vector3, size: Vector3, texture: String, tint: Color, slope: float = 0.0) -> void:
	var visual: MeshInstance3D = game.box(body,position,size,texture,tint)
	visual.rotation.z = slope
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = position
	collision.rotation.z = slope
	body.add_child(collision)

static func build(game: Node3D, body: StaticBody3D) -> void:
	var wood := Color("#967047")
	var trim := Color("#573c29")
	piece(game,body,Vector3(0,.10,0),Vector3(5.4,.20,5.4),"plank",wood)
	# Paredes e pilares (altura 3 m, area interna ~25 m2).
	for x in [-2.65,2.65]:
		for z in [-2.65,2.65]:
			piece(game,body,Vector3(x,1.5,z),Vector3(.18,3,.18),"wood",trim)
	# Fachada: abertura livre de 1.5 m por 2.35 m, voltada para +Z.
	for x in [-1.92,1.92]:
		piece(game,body,Vector3(x,1.5,2.65),Vector3(1.56,3,.16),"plank",wood)
	piece(game,body,Vector3(0,2.71,2.65),Vector3(1.54,.58,.16),"plank",wood)
	for x in [-.79,.79]:
		game.box(body,Vector3(x,1.18,2.74),Vector3(.09,2.36,.10),"wood",trim)
	# Parede traseira com janela de 1.6 x 1.2 m.
	for x in [-1.78,1.78]:
		piece(game,body,Vector3(x,1.5,-2.65),Vector3(1.86,3,.16),"plank",wood)
	for floor_data in [[.56,1.12],[2.52,.96]]:
		piece(game,body,Vector3(0,float(floor_data[0]),-2.65),Vector3(1.70,float(floor_data[1]),.16),"plank",wood)
	# Janelas laterais.
	for side in [-1,1]:
		var x := float(side)*2.65
		for z in [-1.78,1.78]:
			piece(game,body,Vector3(x,1.5,z),Vector3(.16,3,1.86),"plank",wood)
		for floor_data in [[.56,1.12],[2.52,.96]]:
			piece(game,body,Vector3(x,float(floor_data[0]),0),Vector3(.16,float(floor_data[1]),1.70),"plank",wood)
		# Duas aguas: cumeeira ~4.25 m e beirais ~2.9 m.
		piece(game,body,Vector3(float(side)*1.35,3.56,0),Vector3(3.15,.16,6.05),"roof",Color("#68452f"),float(side)*.46)
	# Caixilhos e vidro sem colisao: permitem visibilidade e passagem de luz.
	for z in [-2.75]:
		for x in [-.85,.85]:
			game.box(body,Vector3(x,1.51,z),Vector3(.06,1.23,.06),"wood",trim)
		game.box(body,Vector3(0,1.51,z),Vector3(1.72,.06,.06),"wood",trim)
		var pane: MeshInstance3D = game.box(body,Vector3(0,1.51,z),Vector3(1.60,1.11,.025),"glass",Color("#9bbbc0"))
		pane.transparency = .55
	for side in [-1,1]:
		var x := float(side)*2.75
		for z in [-.85,.85]:
			game.box(body,Vector3(x,1.51,z),Vector3(.06,1.23,.06),"wood",trim)
		game.box(body,Vector3(x,1.51,0),Vector3(.06,.06,1.72),"wood",trim)
		var pane: MeshInstance3D = game.box(body,Vector3(x,1.51,0),Vector3(.025,1.11,1.60),"glass",Color("#9bbbc0"))
		pane.transparency = .55
