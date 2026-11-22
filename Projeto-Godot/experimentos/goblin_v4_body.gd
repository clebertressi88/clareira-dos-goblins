extends RefCounted
## Corpo V4 inspirado no desenho: silhueta magra, ombros anatomicos,
## couro em camadas, botas de biqueira larga e dedos articulados.
## Malhas independentes ligadas a BoneAttachment3D, sem "borracha".
const FACE = preload("res://experimentos/goblin_v4_face.gd")

static func _part(model: Node3D,bone: String,label: String,
		mesh: Mesh,mat: Material) -> MeshInstance3D:
	return FACE.mesh_part(model,bone,label,mesh,mat)

static func _oval(model: Node3D,bone: String,label: String,pos: Vector3,
		dims: Vector3,mat: Material,rot := Vector3.ZERO) -> void:
	FACE.oval(model,bone,label,pos,dims,mat,rot)

static func _curve(model: Node3D,bone: String,label: String,
		points: Array,width: float,mat: Material) -> void:
	FACE.curve(model,bone,label,points,width,mat)

static func _tube(path: Array,radii: Array,segments := 24,subdivisions := 4) -> ArrayMesh:
	# Corte transversal eliptico e transicoes suaves, nao CylinderMesh.
	var rows: Array=[]
	var radii_out: Array=[]
	for i in range(path.size()-1):
		var p0: Vector3=path[i]
		var p1: Vector3=path[i+1]
		var r0: Vector2=radii[i]
		var r1: Vector2=radii[i+1]
		for j in range(subdivisions):
			var t:=float(j)/float(subdivisions)
			t=t*t*(3.0-2.0*t)
			rows.append(p0.lerp(p1,t))
			radii_out.append(r0.lerp(r1,t))
	rows.append(path[-1])
	radii_out.append(radii[-1])
	var points: Array=[]
	for i in range(rows.size()):
		var center: Vector3=rows[i]
		var tangent: Vector3
		if i==0:
			tangent=(rows[1]-rows[0]).normalized()
		elif i==rows.size()-1:
			tangent=(rows[i]-rows[i-1]).normalized()
		else:
			tangent=(rows[i+1]-rows[i-1]).normalized()
		var normal: Vector3=tangent.cross(Vector3.FORWARD)
		if normal.length_squared()<0.01:
			normal=tangent.cross(Vector3.RIGHT)
		normal=normal.normalized()
		var bitangent:=tangent.cross(normal).normalized()
		for k in range(segments+1):
			var phi:=TAU*float(k)/float(segments)
			var radius: Vector2=radii_out[i]
			var at:=center+normal*cos(phi)*radius.x-bitangent*sin(phi)*radius.y
			points.append(at)
	return FACE.smooth_mesh(points,segments+1,rows.size())

static func _member(model: Node3D,bone: String,label: String,path: Array,
		widths: Array,mat: Material) -> void:
	_part(model,bone,label,_tube(path,widths),mat)

static func _palette(model: Node3D) -> Dictionary:
	# Aproxima a paleta da referencia, sem marcas-d'agua.
	var mat: Dictionary={}
	mat["skin"]=model.call("_material","#879d69",.83,.0)
	mat["skin_light"]=model.call("_material","#a0ae7a",.78,.0)
	mat["shadow"]=model.call("_material","#647c53",.89,.0)
	mat["ear"]=model.call("_material","#b98978",.82,.0,true)
	mat["ear_skin"]=model.call("_material","#879d69",.83,.0,true)
	mat["nose"]=model.call("_material","#c89d7c",.68,.0)
	mat["white"]=model.call("_material","#f1e8cf",.44,.0)
	mat["iris"]=model.call("_material","#b7a453",.40,.0)
	mat["dark"]=model.call("_material","#302923",.50,.0)
	mat["leather"]=model.call("_material","#755040",.82,.0,true)
	mat["leather_light"]=model.call("_material","#986b4b",.77,.0,true)
	mat["leather_dark"]=model.call("_material","#4b3229",.93,.0,true)
	mat["skirt"]=model.call("_material","#79503b",.91,.0,true)
	mat["skirt_light"]=model.call("_material","#936443",.86,.0,true)
	mat["boot"]=model.call("_material","#9f6840",.78,.0)
	mat["boot_dark"]=model.call("_material","#69462f",.84,.0)
	mat["gold"]=model.call("_material","#cba054",.39,.47)
	mat["steel"]=model.call("_material","#afb7b7",.33,.70)
	mat["nail"]=model.call("_material","#c1c394",.65,.0)
	return mat

static func _strap(model: Node3D,side: float,mat: Dictionary) -> void:
	var points: Array=[
		Vector3(side*.268,1.432,.120),
		Vector3(side*.250,1.378,.201),
		Vector3(side*.190,1.282,.222),
		Vector3(side*.120,1.188,.251),
		Vector3(0,1.104,.269)
	]
	FACE.ribbon(model,"Coluna","V4_AlcaCouro"+str(int(side)),
		points,[.047,.045,.043,.039,.030],mat["leather"])
	# Costura fina e discreta sobre cada correia.
	var seam: Array=[]
	for p in points:
		var v: Vector3=p
		v.z+=.009
		seam.append(v)
	_curve(model,"Coluna","V4_CosturaCouro"+str(int(side)),
		seam,.006,mat["leather_light"])

static func _skirt(model: Node3D,mat: Dictionary) -> void:
	# Paines triangulares, sobrepostos e arredondados em vez de saia-cilindro.
	var segments := 9
	for i in range(segments):
		var angle:=TAU*float(i)/float(segments)
		var next_angle:=angle+TAU*.135
		var rows := 7
		var cols := 7
		var points: Array=[]
		for j in range(rows):
			var t:=float(j)/float(rows-1)
			var r:=lerpf(.280,.355,t)
			var y:=lerpf(.792,.529,t)
			for k in range(cols):
				var u:=float(k)/float(cols-1)
				var a:=lerpf(angle,next_angle,u)
				var hem: float = pow(absf(u-.5)*2.0,1.25)
				var tip:=maxf(0.0,1.0-absf(u-.5)*2.0)
				var height:=y-.061*t*tip+.017*t*hem
				var push:=.012*sin(PI*t)*sin(u*PI)
				points.append(Vector3(sin(a)*(r+push),height,cos(a)*(r+push)))
		var skirt_mesh:=FACE.smooth_mesh(points,cols,rows)
		var dye: Material=mat["skirt"] if i%2==0 else mat["skirt_light"]
		_part(model,"Quadril","V4_PainelSaia"+str(i),skirt_mesh,dye)
		# Pontos de costura proximos ao cinto.
		var a:=angle+TAU*.06
		var px:=Vector3(sin(a)*.291,.785,cos(a)*.291)
		var py:=Vector3(sin(a)*.313,.722,cos(a)*.313)
		_curve(model,"Quadril","V4_CosturaSaia"+str(i),[px,py],.005,mat["leather_dark"])

static func _torso(model: Node3D,mat: Dictionary) -> void:
	var body: Array=[
		Vector4(.773,.042,.061,-.019),
		Vector4(.817,.222,.172,-.020),
		Vector4(.913,.245,.195,-.021),
		Vector4(1.055,.267,.216,-.028),
		Vector4(1.192,.281,.204,-.031),
		Vector4(1.305,.322,.202,-.030),
		Vector4(1.384,.281,.184,-.033),
		Vector4(1.450,.133,.105,-.028),
		Vector4(1.478,.015,.015,-.023)
	]
	_part(model,"Coluna","V4_TorsoUnificado",FACE.loft_y(body),mat["skin"])
	# Torax e abdomen integrados por relevos muito discretos.
	for side in [-1.0,1.0]:
		_oval(model,"Coluna","V4_Peitoral"+str(int(side)),
			Vector3(side*.138,1.286,.161),
			Vector3(.228,.129,.091),mat["skin"])
		_strap(model,side,mat)
		_oval(model,"Coluna","V4_OmbroPeitoral"+str(int(side)),
			Vector3(side*.270,1.349,.040),Vector3(.170,.125,.160),mat["skin"])
	_curve(model,"Coluna","V4_AbdomenSutil",[
		Vector3(-.109,1.012,.168),Vector3(0,.999,.187),Vector3(.109,1.012,.168)
	],.005,mat["shadow"])
	_oval(model,"Coluna","V4_MedalhaoBronze",Vector3(0,1.105,.290),
		Vector3(.105,.103,.054),mat["gold"])
	_oval(model,"Coluna","V4_RebaixoMedalhao",Vector3(0,1.105,.328),
		Vector3(.053,.053,.022),mat["leather"])
	_oval(model,"Quadril","V4_QuadrilEstreito",Vector3(0,.797,-.025),
		Vector3(.493,.246,.404),mat["skin"])
	_oval(model,"Quadril","V4_CintoDeCouro",Vector3(0,.806,-.013),
		Vector3(.626,.126,.449),mat["leather_dark"])
	# Fivela com furo central e pino.
	_oval(model,"Quadril","V4_FivelaDourada",Vector3(0,.804,.226),
		Vector3(.211,.131,.052),mat["gold"])
	_oval(model,"Quadril","V4_BuracoFivela",Vector3(0,.802,.262),
		Vector3(.128,.074,.024),mat["leather_dark"])
	_curve(model,"Quadril","V4_PinoFivela",[
		Vector3(-.060,.802,.289),Vector3(.050,.802,.289)
	],.010,mat["gold"])
	_skirt(model,mat)

static func _arm(model: Node3D,side: float,mat: Dictionary) -> void:
	var left: bool=side<0.0
	var label := "Esq" if left else "Dir"
	var upper := "OmbroEsq" if left else "OmbroDir"
	var elbow := "CotoveloEsq" if left else "CotoveloDir"
	var hand := "MaoEsq" if left else "MaoDir"
	var a:=Vector3(.313*side,1.316,.016)
	var b:=Vector3(.455*side,1.044,.020)
	var c:=Vector3(.507*side,.815,.049)
	_oval(model,upper,"V4_Deltoide"+label,a,Vector3(.217,.228,.211),mat["skin"])
	_member(model,upper,"V4_ParteSuperiorBraco"+label,[
		a,a.lerp(b,.26)+Vector3(.019*side,0,.002),a.lerp(b,.60),b
	],[Vector2(.110,.104),Vector2(.115,.109),Vector2(.101,.097),Vector2(.088,.083)],mat["skin"])
	_oval(model,elbow,"V4_ArticulacaoCotovelo"+label,b,
		Vector3(.161,.158,.160),mat["skin"])
	_member(model,elbow,"V4_Antebraco"+label,[
		b,b.lerp(c,.26),b.lerp(c,.68),c
	],[Vector2(.087,.084),Vector2(.103,.094),Vector2(.087,.075),Vector2(.070,.069)],mat["skin"])
	_oval(model,hand,"V4_MaoPulso"+label,c,
		Vector3(.140,.130,.141),mat["skin"])
	_oval(model,hand,"V4_PulseiraDourada"+label,c+Vector3(0,-.016,0),
		Vector3(.187,.093,.180),mat["gold"])
	var palm:=c+Vector3(.015*side,-.120,.019)
	_oval(model,hand,"V4_Palma"+label,palm,
		Vector3(.187,.245,.145),mat["skin"])
	# Quatro dedos longos com falanges, sem luvas volumosas.
	for f in range(4):
		var off: float=(float(f)-1.5)*.039
		var length: float=.099+(.023 if f==1 or f==2 else .007)
		var v:=Vector3(palm.x+off,palm.y-.083,palm.z+.055)
		_member(model,hand,"V4_Dedo"+label+str(f),[
			v,
			v+Vector3(-side*.012,-length*.54,.039),
			v+Vector3(-side*.019,-length,.073)
		],[Vector2(.023,.023),Vector2(.023,.021),Vector2(.014,.013)],mat["skin"])
		_oval(model,hand,"V4_Unha"+label+str(f),
			v+Vector3(-side*.019,-length,.086),
			Vector3(.022,.028,.007),mat["nail"])
	var thumb:=palm+Vector3(-side*.074,.022,.025)
	_member(model,hand,"V4_Polegar"+label,[
		thumb,thumb+Vector3(-side*.069,-.061,.047),
		thumb+Vector3(-side*.056,-.111,.070)
	],[Vector2(.035,.034),Vector2(.033,.028),Vector2(.020,.019)],mat["skin"])

static func _boot_mesh(x: float) -> ArrayMesh:
	# Sapato modelado sobre o eixo Z, com sola achatada e biqueira redonda.
	var sections: Array=[
		Vector4(-.114,.101,.101,.115),
		Vector4(-.065,.141,.108,.125),
		Vector4(.020,.153,.121,.126),
		Vector4(.140,.160,.103,.121),
		Vector4(.259,.163,.090,.117),
		Vector4(.358,.135,.078,.109),
		Vector4(.411,.072,.046,.107),
		Vector4(.423,.006,.006,.104)
	]
	var rows := (sections.size()-1)*4+1
	var cols := 33
	var points: Array=[]
	for j in range(rows):
		var sec: int=mini(int(j/4),sections.size()-2)
		var t:=float(j-sec*4)/4.0
		t=t*t*(3.0-2.0*t)
		var profile: Vector4=sections[sec].lerp(sections[sec+1],t)
		for k in range(cols):
			var a:=TAU*float(k)/float(cols-1)
			var at:=Vector3(x+cos(a)*profile.y,
				profile.w-sin(a)*profile.z,
				profile.x)
			points.append(at)
	return FACE.smooth_mesh(points,cols,rows)

static func _boot(model: Node3D,side: float,mat: Dictionary) -> void:
	var left: bool=side<0.0
	var label := "Esq" if left else "Dir"
	var ankle := "TornozeloEsq" if left else "TornozeloDir"
	var x: float=.167*side
	# Cano/couro ligado ao pé em uma silhueta contínua.
	_member(model,ankle,"V4_CanoBota"+label,[
		Vector3(x,.378,.027),
		Vector3(x,.309,.030),
		Vector3(x,.221,.037),
		Vector3(x,.158,.054)
	],[Vector2(.119,.111),Vector2(.130,.121),
	Vector2(.119,.110),Vector2(.102,.099)],mat["boot"])
	_part(model,ankle,"V4_BotaInteira"+label,_boot_mesh(x),mat["boot"])
	# Sola discreta junto ao solo, nao varios aneis empilhados.
	_oval(model,ankle,"V4_Sola"+label,Vector3(x,.048,.145),
		Vector3(.323,.055,.477),mat["boot_dark"])
	_oval(model,ankle,"V4_DobraCano"+label,Vector3(x,.365,.020),
		Vector3(.255,.061,.249),mat["leather_light"])
	_curve(model,ankle,"V4_CosturaBota"+label,[
		Vector3(x-.101,.168,.260),
		Vector3(x,.157,.288),
		Vector3(x+.101,.168,.260)
	],.007,mat["leather_dark"])
	for line_idx in range(3):
		var yy:=.263-float(line_idx)*.040
		_curve(model,ankle,"V4_Cordao"+label+str(line_idx),[
			Vector3(x-.062,yy,.143),Vector3(x+.062,yy,.143)
		],.008,mat["leather_dark"])

static func _legs(model: Node3D,mat: Dictionary) -> void:
	for side in [-1.0,1.0]:
		var left: bool=side<0.0
		var label := "Esq" if left else "Dir"
		var upper := "CoxaEsq" if left else "CoxaDir"
		var knee := "JoelhoEsq" if left else "JoelhoDir"
		var a:=Vector3(.158*side,.759,-.015)
		var b:=Vector3(.169*side,.492,.004)
		var c:=Vector3(.170*side,.220,.029)
		_oval(model,upper,"V4_InicioCoxa"+label,a,
			Vector3(.194,.166,.186),mat["skin"])
		_member(model,upper,"V4_Coxa"+label,[
			a,a.lerp(b,.33),a.lerp(b,.71),b
		],[Vector2(.128,.133),Vector2(.133,.124),
		Vector2(.116,.113),Vector2(.097,.098)],mat["skin"])
		_oval(model,knee,"V4_Rotula"+label,b,
			Vector3(.182,.176,.175),mat["skin"])
		_member(model,knee,"V4_Panturrilha"+label,[
			b,b.lerp(c,.30),b.lerp(c,.67),c
		],[Vector2(.097,.102),Vector2(.117,.108),
		Vector2(.094,.098),Vector2(.080,.081)],mat["skin"])
		_boot(model,side,mat)

static func _equipment(model: Node3D,mat: Dictionary) -> void:
	# Equipamento de teste: continua completamente separado do corpo.
	var grip:=Vector3(.524,.682,.135)
	var sword: Array=model.get("sword_parts")
	var shield: Array=model.get("shield_parts")
	sword.append(model.call("_rod","MaoDir","V4_CaboEspada",
		grip,grip+Vector3(0,-.18,.01),.025,mat["leather_dark"]))
	sword.append(model.call("_rod","MaoDir","V4_LaminaEspada",
		grip+Vector3(0,-.18,.01),grip+Vector3(0,-.55,.01),
		.032,mat["steel"],.003))
	sword.append(model.call("_rod","MaoDir","V4_GuardaEspada",
		grip+Vector3(-.09,-.20,.01),grip+Vector3(.09,-.20,.01),
		.016,mat["gold"]))
	_oval(model,"MaoEsq","V4_Escudo",Vector3(-.58,.74,.17),
		Vector3(.305,.395,.073),mat["leather"])
	_oval(model,"MaoEsq","V4_Umbo",Vector3(-.58,.74,.212),
		Vector3(.131,.137,.050),mat["gold"])
	for path in ["V4_Escudo","V4_Umbo"]:
		var found: Array=model.find_children(path,"MeshInstance3D",true,false)
		if not found.is_empty():
			shield.append(found[0])

static func sculpt(model: Node3D) -> void:
	var mat:=_palette(model)
	FACE.build(model,mat)
	_torso(model,mat)
	_arm(model,-1.0,mat)
	_arm(model,1.0,mat)
	_legs(model,mat)
	_equipment(model,mat)
	model.set_meta("modelo_goblin_v4",true)
	model.set_meta("referencia_visual","goblin_orelhas_longas_olhos_fundos")
