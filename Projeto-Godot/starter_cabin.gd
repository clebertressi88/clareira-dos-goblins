extends RefCounted
# Cabana goblin de inicio: interior funcional; decoracoes nao geram colisao.
# Porta no lado +Z. Nunca bloquear o vao de 1.5 m x 2.35 m.

static func piece(game, body: StaticBody3D, pos: Vector3, size: Vector3, texture: String, color: Color, roll: float = 0.0) -> void:
	var visual: MeshInstance3D = game.box(body,pos,size,texture,color)
	visual.rotation.z = roll
	preload("res://cabin_materials.gd").apply(game,visual,"roof" if texture=="roof" else ("clay" if texture=="plank" else "wood"),color)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = pos
	collision.rotation.z = roll
	body.add_child(collision)

static func trim_box(game, body: Node3D, pos: Vector3, size: Vector3, color: Color, angle: float = 0.0, texture: String = "wood") -> void:
	var visual: MeshInstance3D = game.box(body,pos,size,texture,color)
	visual.rotation.z = angle
	preload("res://cabin_materials.gd").apply(game,visual,"roof" if texture=="roof" else ("clay" if texture=="plank" else "wood"),color)

static func beam(game, body: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var length := a.distance_to(b)
	if length < .01:
		return
	var visual: MeshInstance3D = game.cylinder(body,(a+b)*.5,radius,length,"wood",color)
	visual.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	preload("res://cabin_materials.gd").apply(game,visual,"wood",color)

static func build(game, body: StaticBody3D) -> void:
	var plaster := Color("#766d4e")
	var clay := Color("#857052")
	var timber := Color("#392a1e")
	var wood := Color("#6f5132")
	var moss := Color("#475e31")
	var roof := Color("#4b4b31")
	# Fundacao elevada e piso transitavel com juntas irregulares.
	piece(game,body,Vector3(0,.12,0),Vector3(5.4,.24,5.4),"wood",wood)
	for i in range(11):
		var x := -2.45+float(i)*.48
		trim_box(game,body,Vector3(x,.248,0),Vector3(.025,.012,5.25),timber)
	# Rampa sem degrau, ajustada ao terreno real em cada cabana.
	var ramp_length := 1.8
	var outside := body.to_global(Vector3(0,0,2.7+ramp_length))
	var low := minf(.24,float(game.ground(outside.x,outside.z))-body.global_position.y-.06)
	var rise := .24-low
	var angle := atan2(rise,ramp_length)
	var ramp_size := Vector3(1.46,.12,sqrt(ramp_length*ramp_length+rise*rise))
	var ramp_pos := Vector3(0,(.24+low)*.5-.06,2.7+ramp_length*.5)
	var ramp: MeshInstance3D = game.box(body,ramp_pos,ramp_size,"wood",wood)
	ramp.rotation.x = angle
	preload("res://cabin_materials.gd").apply(game,ramp,"wood",wood)
	var ramp_shape := BoxShape3D.new()
	ramp_shape.size = ramp_size
	var ramp_collision := CollisionShape3D.new()
	ramp_collision.shape = ramp_shape
	ramp_collision.position = ramp_pos
	ramp_collision.rotation.x = angle
	body.add_child(ramp_collision)
	# Estrutura solida: paredes de barro/taipa, madeira aparente e aberturas reais.
	for x in [-2.65,2.65]:
		for z in [-2.65,2.65]:
			piece(game,body,Vector3(x,1.5,z),Vector3(.20,3.0,.20),"wood",timber)
			beam(game,body,Vector3(x,0,z),Vector3(x+(.14 if x<0 else -.12),3.10,z),.13,wood)
	# Entrada principal com porta SEM folha: passagem sempre livre.
	for x in [-1.92,1.92]:
		piece(game,body,Vector3(x,1.5,2.65),Vector3(1.56,3.0,.16),"plank",clay)
	piece(game,body,Vector3(0,2.71,2.65),Vector3(1.54,.58,.16),"plank",plaster)
	for x in [-.83,.83]:
		beam(game,body,Vector3(x,.28,2.80),Vector3(x+(.10 if x<0 else -.09),2.64,2.80),.085,timber)
	beam(game,body,Vector3(-.93,2.43,2.81),Vector3(.93,2.52,2.81),.10,wood)
	# Parede traseira; janela central.
	for x in [-1.78,1.78]:
		piece(game,body,Vector3(x,1.5,-2.65),Vector3(1.86,3,.16),"plank",plaster)
	for dimensions in [[.56,1.12],[2.52,.96]]:
		var y: float = dimensions[0]
		var h: float = dimensions[1]
		piece(game,body,Vector3(0,float(y),-2.65),Vector3(1.70,float(h),.16),"plank",clay)
	# Laterais com janelas e molduras de madeira.
	for side in [-1,1]:
		var x := float(side)*2.65
		for z in [-1.78,1.78]:
			piece(game,body,Vector3(x,1.5,z),Vector3(.16,3,1.86),"plank",clay)
		for dimensions in [[.56,1.12],[2.52,.96]]:
			var y: float = dimensions[0]
			var h: float = dimensions[1]
			piece(game,body,Vector3(x,float(y),0),Vector3(.16,float(h),1.70),"plank",plaster)
		# Travessas tortas nas paredes, fora do caminho do jogador.
		for z in [-1.85,1.85]:
			beam(game,body,Vector3(x+float(side)*.11,.42,z-.56),Vector3(x+float(side)*.11,2.75,z+.55),.065,timber)
	# Montantes e travas da fachada: identidade de construcoes goblins.
	for x in [-2.48,2.48]:
		beam(game,body,Vector3(x,.30,2.80),Vector3(x+(.24 if x<0 else -.22),2.85,2.80),.09,timber)
	beam(game,body,Vector3(-2.68,2.72,2.78),Vector3(2.67,2.79,2.78),.065,timber)
	for side in [-1.0,1.0]:
		beam(game,body,Vector3(side*.95,.55,2.78),Vector3(side*2.68,.62,2.78),.065,timber)
	# Telhado alto, duas aguas; base com colisao inclinada.
	for side in [-1,1]:
		var s := float(side)
		var slope := -s*.46
		piece(game,body,Vector3(s*1.35,3.56,0),Vector3(3.15,.16,6.05),"roof",roof,slope)
		# Telhas de madeira desalinhadas, em fiadas sobre as duas aguas.
		for row in range(5):
			for col in range(11):
				var along := float(row)
				var z := -2.75+float(col)*.54+(.12 if row%2 else 0.0)
				var x := s*(.28+along*.57)
				var y := 4.17-along*.29
				var shade := Color("#62573a") if (row+col)%4==0 else (Color("#3b452d") if (row*7+col)%9==0 else Color("#756045"))
				trim_box(game,body,Vector3(x,y+.13,z),Vector3(.68,.055,.59),shade,slope,"roof")
	# Cumeeira e madeiramento das extremidades.
	beam(game,body,Vector3(0,4.24,-3.17),Vector3(0,4.24,3.20),.12,timber)
	for z in [-2.96,2.96]:
		beam(game,body,Vector3(-2.92,2.93,z),Vector3(0,4.26,z),.12,wood)
		beam(game,body,Vector3(0,4.26,z),Vector3(2.92,2.93,z),.12,wood)
		beam(game,body,Vector3(-2.95,2.93,z),Vector3(2.95,2.93,z),.08,timber)
	# Toldo irregular sobre a entrada, alto e sem colisao no vao.
	for x in [-1.60,1.60]:
		beam(game,body,Vector3(x,2.62,2.84),Vector3(x,2.61,4.00),.095,timber)
	for i in range(7):
		var x := -1.50+float(i)*.50
		trim_box(game,body,Vector3(x,2.72+float(i%3)*.025,3.39),Vector3(.57,.075,1.24),Color("#504630") if i%2==0 else Color("#6c5936"),0.0,"roof")
	# Janelas totalmente abertas: sem vidro, planos opacos ou colisoes invisiveis.
	# Apenas moldura grosseira e uma pequena travessa de madeira fora do centro.
	for z in [-2.75]:
		for x in [-.85,.85]:
			trim_box(game,body,Vector3(x,1.51,z),Vector3(.075,1.23,.075),timber)
		trim_box(game,body,Vector3(0,1.51,z),Vector3(1.75,.08,.075),timber)
		trim_box(game,body,Vector3(-.22,1.52,z),Vector3(.055,1.20,.06),wood,.09)
	for side in [-1,1]:
		var x := float(side)*2.75
		for z in [-.85,.85]:
			trim_box(game,body,Vector3(x,1.51,z),Vector3(.075,1.23,.075),timber)
		trim_box(game,body,Vector3(x,1.51,0),Vector3(.075,.08,1.75),timber)
		trim_box(game,body,Vector3(x,1.51,-.25),Vector3(.06,.90,.055),wood,.08)
	# Pequenos reparos assimetricos, ferragens e bandeirola tribal.
	for k in range(8):
		var x := -2.18+float(k%4)*1.35
		var z := 2.75 if k<4 else -2.75
		trim_box(game,body,Vector3(x,.52+float(k%3)*.43,z),Vector3(.32,.12,.055),wood,.13 if k%2 else -.12)
	for side in [-1,1]:
		trim_box(game,body,Vector3(float(side)*.65,.28,2.86),Vector3(.19,.04,.06),Color("#323128"))
	# Poste de totem lateral nao interfere na passagem.
	beam(game,body,Vector3(-2.12,.2,3.22),Vector3(-2.04,3.35,3.25),.075,timber)
	trim_box(game,body,Vector3(-2.04,3.15,3.25),Vector3(.59,.38,.065),moss,.13)
	trim_box(game,body,Vector3(-2.04,3.02,3.30),Vector3(.29,.06,.075),Color("#c4a568"))
