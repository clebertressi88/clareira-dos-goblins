extends Node3D
## GOBLIN V3 - PERSONAGEM 3D MODULAR / LABORATORIO
## Reconstrucao original baseada na silhueta enviada pelo usuario.
## Sem textura com marca d'agua. Cada membro e uma malha independente.
## As pecas acompanham BoneAttachment3D em um Skeleton3D unico:
## nao ha pesos de vertices que estiquem os membros.
## A cena da partida continua usando o goblin anterior ate aprovacao.

const NAMES := [
	"Quadril","Coluna","Pescoco","Cabeca",
	"OmbroEsq","CotoveloEsq","MaoEsq",
	"OmbroDir","CotoveloDir","MaoDir",
	"CoxaEsq","JoelhoEsq","TornozeloEsq",
	"CoxaDir","JoelhoDir","TornozeloDir"
]
const PARENTS := [-1,0,1,2,1,4,5,1,7,8,0,10,11,0,13,14]
const JOINTS := [
	Vector3(0,.82,0),Vector3(0,1.18,0),Vector3(0,1.43,0),
	Vector3(0,1.61,0),Vector3(-.32,1.31,0),
	Vector3(-.46,1.04,.01),Vector3(-.51,.81,.05),
	Vector3(.32,1.31,0),Vector3(.46,1.04,.01),
	Vector3(.51,.81,.05),Vector3(-.16,.76,0),
	Vector3(-.17,.49,.01),Vector3(-.17,.21,.03),
	Vector3(.16,.76,0),Vector3(.17,.49,.01),Vector3(.17,.21,.03)
]
var skeleton: Skeleton3D
var joints: Dictionary = {}
var skins: Dictionary = {}
var sword_parts: Array[Node3D] = []
var shield_parts: Array[Node3D] = []
var sword_equipped := false
var shield_equipped := false
var walk_phase := 0.0
var walk_blend := 0.0
var part_count := 0
var skeletons: Array[Skeleton3D] = []

func _ready() -> void:
	install()

func _material(code: String, rough := .88, metallic := .0, both_sides := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(code)
	m.roughness = rough
	m.metallic = metallic
	if both_sides:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _palette() -> void:
	skins = {
		"pele":_material("#779c58"),
		"pele_clara":_material("#95b576"),
		"pele_sombra":_material("#52764a"),
		"orelha":_material("#b7806e"),
		"nariz":_material("#cc9c7b"),
		"olho":_material("#f3e5bb",.43),
		"iris":_material("#a79741",.38),
		"pupila":_material("#241d19",.24),
		"luz":_material("#faf9e9",.2),
		"boca":_material("#463d2e"),
		"couro":_material("#774b38"),
		"couro_escuro":_material("#4e3027"),
		"saia":_material("#82563e",.96,0,true),
		"bota":_material("#955c36"),
		"sola":_material("#4c3328"),
		"ouro":_material("#d2a24b",.29,.48),
		"metal":_material("#bfc7c8",.24,.7)
	}

func install() -> bool:
	if is_instance_valid(skeleton):
		return true
	_palette()
	skeleton = Skeleton3D.new()
	skeleton.name = "EsqueletoGoblinV3"
	add_child(skeleton)
	for i in range(NAMES.size()):
		var bone_idx: int = skeleton.add_bone(NAMES[i])
		var parent_idx: int = int(PARENTS[i])
		if parent_idx >= 0:
			skeleton.set_bone_parent(bone_idx,parent_idx)
		var rest: Vector3 = JOINTS[i] if parent_idx < 0 else JOINTS[i] - JOINTS[parent_idx]
		skeleton.set_bone_rest(bone_idx,Transform3D(Basis.IDENTITY,rest))
	skeleton.reset_bone_poses()
	skeletons.append(skeleton)
	for i in range(NAMES.size()):
		var anchor := BoneAttachment3D.new()
		anchor.name = "Junta_" + NAMES[i]
		anchor.bone_name = NAMES[i]
		skeleton.add_child(anchor)
		joints[NAMES[i]] = anchor
	_build_character()
	set_equipment(false,false)
	set_meta("skeleton_ready",true)
	set_meta("modelo_goblin_v3",true)
	set_meta("articulacao_sem_deformacao",true)
	return part_count > 35

func _mesh_on(bone_name: String, piece_name: String, mesh: Mesh,
		location: Vector3, rotation: Vector3, dimensions: Vector3,
		material: Material) -> MeshInstance3D:
	var bone_id: int = skeleton.find_bone(bone_name)
	var anchor: BoneAttachment3D = joints[bone_name]
	var item := MeshInstance3D.new()
	item.name = piece_name
	item.mesh = mesh
	item.material_override = material
	anchor.add_child(item)
	var desired := Transform3D(Basis.from_euler(rotation).scaled(dimensions),location)
	item.transform = skeleton.get_bone_global_rest(bone_id).affine_inverse()*desired
	part_count += 1
	return item

func _oval(bone_name: String, label: String, pos: Vector3,
		dims: Vector3, material: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius=.5
	shape.height=1.0
	shape.radial_segments=22
	shape.rings=12
	return _mesh_on(bone_name,label,shape,pos,rot,dims,material)

func _box(bone_name: String, label: String, pos: Vector3,
		dims: Vector3, material: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size=Vector3.ONE
	return _mesh_on(bone_name,label,shape,pos,rot,dims,material)

func _rod(bone_name: String, label: String, origin: Vector3, target: Vector3,
		radius: float, material: Material, end_radius := -1.0) -> MeshInstance3D:
	var vec := target-origin
	var shape := CylinderMesh.new()
	shape.height=vec.length()
	shape.bottom_radius=radius
	shape.top_radius=radius if end_radius<0.0 else end_radius
	shape.radial_segments=14
	shape.rings=1
	var direction := vec.normalized()
	var spin := Basis(Quaternion(Vector3.UP,direction))
	return _mesh_on(bone_name,label,shape,(origin+target)*.5,
		spin.get_euler(),Vector3.ONE,material)

func _poly(bone_name: String, label: String, points: PackedVector3Array,
		material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,points.size()-1):
		st.add_vertex(points[0])
		st.add_vertex(points[i])
		st.add_vertex(points[i+1])
	st.generate_normals()
	var mesh := st.commit()
	_mesh_on(bone_name,label,mesh,Vector3.ZERO,Vector3.ZERO,Vector3.ONE,material)

func _ear(side: float) -> void:
	var a := side
	var outer := PackedVector3Array([
		Vector3(a*.32,1.74,.075), Vector3(a*.42,1.96,.03),
		Vector3(a*.86,2.09,-.035), Vector3(a*.70,1.79,.06),
		Vector3(a*.49,1.64,.10)
	])
	var inner := PackedVector3Array([
		Vector3(a*.42,1.78,.095),Vector3(a*.48,1.91,.065),
		Vector3(a*.76,2.015,.012),Vector3(a*.65,1.78,.085),
		Vector3(a*.49,1.70,.12)
	])
	_poly("Cabeca","Orelha%d" % int(a),outer,skins["pele"])
	_poly("Cabeca","InteriorOrelha%d" % int(a),inner,skins["orelha"])

func _skirt_panel(x: float, offset: float, n: int) -> void:
	var points := PackedVector3Array([
		Vector3(x-.13,.79,.23+offset),
		Vector3(x+.13,.79,.23+offset),
		Vector3(x+.15,.57,.22+offset),
		Vector3(x,.49,.22+offset),
		Vector3(x-.16,.56,.22+offset)
	])
	_poly("Quadril","SaiaPainel%d" % n,points,skins["saia"])

func _build_character() -> void:
	# Cranio, orelhas pontudas, pequeno chifre, olhos, nariz grande e boca.
	_oval("Cabeca","Cabeca",Vector3(0,1.74,.01),Vector3(.78,.61,.55),skins["pele"])
	_oval("Cabeca","Maxilar",Vector3(0,1.51,.10),Vector3(.53,.29,.46),skins["pele"])
	_oval("Cabeca","SombraQueixo",Vector3(0,1.46,.29),Vector3(.35,.055,.07),skins["pele_sombra"])
	_ear(-1.0)
	_ear(1.0)
	var horn := CylinderMesh.new()
	horn.top_radius=0
	horn.bottom_radius=.10
	horn.height=.21
	horn.radial_segments=16
	_mesh_on("Cabeca","Chifre",horn,Vector3(0,2.145,-.035),Vector3.ZERO,Vector3.ONE,skins["ouro"])
	for side in [-1.0,1.0]:
		var x: float = .185*side
		var suffix := "E" if side<0 else "D"
		_oval("Cabeca","Olho"+suffix,Vector3(x,1.735,.276),
			Vector3(.167,.147,.119),skins["olho"])
		_oval("Cabeca","Iris"+suffix,Vector3(x,1.735,.355),
			Vector3(.097,.108,.041),skins["iris"])
		_oval("Cabeca","Pupila"+suffix,Vector3(x,1.737,.382),
			Vector3(.047,.070,.022),skins["pupila"])
		_oval("Cabeca","Brilho"+suffix,Vector3(x-.02,1.767,.398),
			Vector3(.021,.023,.009),skins["luz"])
		_oval("Cabeca","Sobrancelha"+suffix,Vector3(x,1.862,.286),
			Vector3(.27,.075,.106),skins["pele_sombra"],
			Vector3(0,0,-.15*side))
	_oval("Cabeca","Nariz",Vector3(0,1.624,.393),
		Vector3(.29,.29,.29),skins["nariz"])
	_oval("Cabeca","PontaNariz",Vector3(0,1.584,.496),
		Vector3(.20,.16,.17),skins["nariz"])
	for x in [-.075,.075]:
		_oval("Cabeca","Narina",Vector3(x,1.551,.554),
			Vector3(.029,.015,.012),skins["couro_escuro"])
	_oval("Cabeca","Boca",Vector3(0,1.468,.341),
		Vector3(.31,.034,.028),skins["boca"])
	_oval("Cabeca","Labio",Vector3(0,1.441,.348),
		Vector3(.26,.035,.033),skins["pele_clara"])
	# Pescoço, tronco esguio, peitoral e alças de couro em V.
	_oval("Pescoco","Pescoco",Vector3(0,1.42,0),Vector3(.24,.22,.26),skins["pele"])
	_oval("Coluna","Torso",Vector3(0,1.16,0),Vector3(.68,.69,.47),skins["pele"])
	_oval("Coluna","Peitoral",Vector3(0,1.29,.15),
		Vector3(.60,.28,.26),skins["pele_clara"])
	_oval("Coluna","Barriga",Vector3(0,1.02,.16),
		Vector3(.46,.41,.32),skins["pele"])
	_rod("Coluna","CorreiaE",Vector3(-.29,1.39,.185),
		Vector3(0,1.04,.263),.047,skins["couro"])
	_rod("Coluna","CorreiaD",Vector3(.29,1.39,.185),
		Vector3(0,1.04,.263),.047,skins["couro"])
	_oval("Coluna","ArgolaPeitoral",Vector3(0,1.04,.303),
		Vector3(.118,.118,.065),skins["ouro"])
	_oval("Coluna","MioloPeitoral",Vector3(0,1.04,.345),
		Vector3(.052,.052,.018),skins["couro"])
	# Cintura, cinto, saia de couro e fivela.
	_oval("Quadril","Quadril",Vector3(0,.80,0),
		Vector3(.51,.30,.42),skins["pele"])
	_oval("Quadril","Cinto",Vector3(0,.805,.02),
		Vector3(.68,.165,.54),skins["couro"])
	_box("Quadril","Fivela",Vector3(0,.811,.300),
		Vector3(.24,.15,.067),skins["ouro"])
	_box("Quadril","CentroFivela",Vector3(0,.811,.348),
		Vector3(.10,.055,.015),skins["couro_escuro"])
	_skirt_panel(-.22,-.007,0)
	_skirt_panel(0,.008,1)
	_skirt_panel(.22,-.007,2)
	# Bracos independentes em ombros/cotovelos e maos.
	for side in [-1.0,1.0]:
		var left := side<0.0
		var upper := "OmbroEsq" if left else "OmbroDir"
		var lower := "CotoveloEsq" if left else "CotoveloDir"
		var hand := "MaoEsq" if left else "MaoDir"
		var shoulder := Vector3(.32*side,1.31,0)
		var elbow := Vector3(.46*side,1.04,.01)
		var wrist := Vector3(.51*side,.81,.05)
		_oval(upper,"Ombreira",shoulder,Vector3(.22,.22,.23),skins["pele"])
		_rod(upper,"Braco",shoulder,elbow,.109,skins["pele"],.088)
		_oval(lower,"ArticulacaoCotovelo",elbow,Vector3(.18,.18,.18),skins["pele"])
		_rod(lower,"Antebraco",elbow,wrist,.087,skins["pele"],.071)
		_oval(hand,"Bracelete",wrist,Vector3(.19,.13,.19),skins["ouro"])
		_oval(hand,"Palma",wrist+Vector3(.013*side,-.09,.025),
			Vector3(.19,.23,.14),skins["pele"])
		for finger in range(3):
			var fx := (.46+float(finger)*.051)*side
			_rod(hand,"Dedo%d" % finger,
				Vector3(fx,.735,.097),Vector3(fx,.666,.125),
				.022,skins["pele"])
	# Pernas completas com coxas, joelhos, canelas, botas e solas.
	for side in [-1.0,1.0]:
		var left := side<0.0
		var thigh := "CoxaEsq" if left else "CoxaDir"
		var knee := "JoelhoEsq" if left else "JoelhoDir"
		var ankle := "TornozeloEsq" if left else "TornozeloDir"
		var hip_pos := Vector3(.16*side,.76,0)
		var knee_pos := Vector3(.17*side,.49,.01)
		var ankle_pos := Vector3(.17*side,.21,.03)
		_oval(thigh,"JuntaQuadril",hip_pos,Vector3(.18,.17,.20),skins["pele"])
		_rod(thigh,"Coxa",hip_pos,knee_pos,.12,skins["pele"],.105)
		_oval(knee,"Rotula",knee_pos,Vector3(.19,.18,.18),skins["pele"])
		_rod(knee,"Canela",knee_pos,ankle_pos,.103,skins["pele"],.078)
		_oval(ankle,"CanoDaBota",Vector3(.17*side,.255,.04),
			Vector3(.25,.26,.26),skins["bota"])
		_oval(ankle,"Bota",Vector3(.17*side,.122,.134),
			Vector3(.315,.225,.440),skins["bota"])
		_oval(ankle,"Sola",Vector3(.17*side,.057,.143),
			Vector3(.32,.060,.455),skins["sola"])
		_oval(ankle,"BordaDaBota",Vector3(.17*side,.345,.04),
			Vector3(.25,.07,.26),skins["ouro"])
	# Equipamentos separados em BoneAttachment3D: ocultos por padrao.
	var grip := Vector3(.53,.69,.13)
	sword_parts.append(_rod("MaoDir","CaboEspada",grip,
		grip+Vector3(.0,-.22,.01),.028,skins["couro_escuro"]))
	sword_parts.append(_rod("MaoDir","LaminaEspada",
		grip+Vector3(0,-.22,.01),grip+Vector3(0,-.59,.01),.039,skins["metal"],.004))
	sword_parts.append(_rod("MaoDir","GuardaEspada",
		grip+Vector3(-.11,-.23,.01),grip+Vector3(.11,-.23,.01),.024,skins["ouro"]))
	shield_parts.append(_oval("MaoEsq","EscudoMadeira",Vector3(-.59,.79,.16),
		Vector3(.36,.44,.095),skins["couro"]))
	shield_parts.append(_oval("MaoEsq","ReforcoEscudo",Vector3(-.59,.79,.219),
		Vector3(.17,.17,.062),skins["ouro"]))

func set_equipment(sword: bool, shield: bool) -> void:
	sword_equipped=sword
	shield_equipped=shield
	for part in sword_parts:
		if is_instance_valid(part):
			part.visible=sword
	for part in shield_parts:
		if is_instance_valid(part):
			part.visible=shield

func animate(velocity: Vector3, dt: float, grounded: bool=true) -> void:
	if not is_instance_valid(skeleton):
		return
	var speed := Vector2(velocity.x,velocity.z).length()
	var target := clampf(speed/2.6,0,1) if grounded else 0.0
	walk_blend=move_toward(walk_blend,target,dt*6.0)
	var running := clampf((speed-2.4)/1.5,0,1)
	var frequency := lerpf(6.4,10.6,running)
	walk_phase=fposmod(walk_phase+dt*frequency,TAU)
	var step := sin(walk_phase)*walk_blend
	var swing := (.40+running*.35)
	var knees := (.24+running*.55)
	var arms := (.29+running*.43)
	# Manter a posicao de descanso do quadril: nao substituir pela origem!
	var rest_hip := skeleton.get_bone_rest(0).origin
	var bounce := maxf(0,sin(walk_phase*2.0))*(.016+.024*running)*walk_blend
	skeleton.set_bone_pose_position(0,rest_hip+Vector3(0,bounce,0))
	skeleton.set_bone_pose_rotation(10,Quaternion(Vector3.RIGHT,step*swing))
	skeleton.set_bone_pose_rotation(13,Quaternion(Vector3.RIGHT,-step*swing))
	skeleton.set_bone_pose_rotation(11,Quaternion(Vector3.RIGHT,maxf(0,-step)*knees))
	skeleton.set_bone_pose_rotation(14,Quaternion(Vector3.RIGHT,maxf(0,step)*knees))
	skeleton.set_bone_pose_rotation(12,Quaternion(Vector3.RIGHT,-step*.20))
	skeleton.set_bone_pose_rotation(15,Quaternion(Vector3.RIGHT,step*.20))
	skeleton.set_bone_pose_rotation(4,Quaternion(Vector3.RIGHT,-step*arms))
	skeleton.set_bone_pose_rotation(7,Quaternion(Vector3.RIGHT,step*arms))
	skeleton.set_bone_pose_rotation(5,Quaternion(Vector3.RIGHT,-maxf(0,-step)*(.18+running*.30)))
	skeleton.set_bone_pose_rotation(8,Quaternion(Vector3.RIGHT,-maxf(0,step)*(.18+running*.30)))
	skeleton.set_bone_pose_rotation(1,Quaternion(Vector3.RIGHT,-running*.16*walk_blend))
	skeleton.set_bone_pose_rotation(3,Quaternion(Vector3.UP,sin(walk_phase)*walk_blend*.016))
