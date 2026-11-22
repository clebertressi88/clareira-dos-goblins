extends RefCounted
## Acabamento visual do goblin V3. Preserva todo o Skeleton3D, as maos e
## a logica de caminhada da cena experimental. Usa formas organicas,
## uma malha de vestuario envolvente e texturas procedurais proprias.
const DETAIL_SHADER: Shader = preload("res://experimentos/goblin_v3_surface.gdshader")

static func _visual_material(color: Color, rough: float, grain: float) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = DETAIL_SHADER
	result.set_shader_parameter("tint",color)
	result.set_shader_parameter("roughness_level",rough)
	result.set_shader_parameter("grain_strength",grain)
	return result

static func _mat(model: Node3D, label: String) -> Material:
	return (model.get("skins") as Dictionary)[label] as Material

static func prepare_palette(model: Node3D) -> void:
	var palette: Dictionary=model.get("skins")
	for key in ["pele","pele_clara","pele_sombra","orelha","nariz","couro","couro_escuro","saia","bota","sola"]:
		var existing := palette[key] as StandardMaterial3D
		var rough := .86
		var grain := .055
		if key in ["couro","couro_escuro","saia","bota","sola"]:
			rough=.78
			grain=.09
		if key=="nariz" or key=="orelha":
			grain=.035
		palette[key]=_visual_material(existing.albedo_color,rough,grain)

static func _remove_primitive_parts(model: Node3D) -> void:
	var old_names := [
		"Cabeca","Maxilar","SombraQueixo","Chifre","Nariz","PontaNariz",
		"Torso","Peitoral","Barriga","Pescoco","Quadril","Cinto",
		"Fivela","CentroFivela","CorreiaE","CorreiaD","ArgolaPeitoral",
		"MioloPeitoral","Ombreira","Braco","ArticulacaoCotovelo",
		"Antebraco","Palma","Bracelete","JuntaQuadril","Coxa",
		"Rotula","Canela","CanoDaBota","Bota","Sola","BordaDaBota",
		"Boca","Labio"
	]
	for node in model.find_children("*","MeshInstance3D",true,false):
		var part := node as MeshInstance3D
		if part==null:
			continue
		var erase := part.name in old_names
		for prefix in ["Orelha","InteriorOrelha","Olho","Iris","Pupila",
				"Brilho","Sobrancelha","Narina","Dedo","SaiaPainel"]:
			if part.name.begins_with(prefix):
				erase=true
		if erase:
			part.queue_free()

static func _piece(model: Node3D,bone: String,name: String,mesh: Mesh,
		pos: Vector3,dims: Vector3,material: Material,
		rotation := Vector3.ZERO) -> MeshInstance3D:
	return model.call("_mesh_on",bone,name,mesh,pos,rotation,dims,material) as MeshInstance3D

static func _orb(model: Node3D,bone: String,name: String,pos: Vector3,
		dims: Vector3,material: Material,rotation := Vector3.ZERO) -> MeshInstance3D:
	return model.call("_oval",bone,name,pos,dims,material,rotation) as MeshInstance3D

static func _line(model: Node3D,bone: String,prefix: String,points: Array,
		radius: float,material: Material) -> void:
	for i in range(points.size()-1):
		model.call("_rod",bone,prefix+str(i),points[i],points[i+1],radius,material)

static func _surface(points: Array,side_sign := 1) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,points.size(),3):
		if side_sign==1:
			st.add_vertex(points[i])
			st.add_vertex(points[i+1])
			st.add_vertex(points[i+2])
		else:
			st.add_vertex(points[i])
			st.add_vertex(points[i+2])
			st.add_vertex(points[i+1])
	st.generate_normals()
	return st.commit()

static func _sculpted_mesh(kind: String) -> ArrayMesh:
	var uv := PackedVector3Array()
	var indexed := PackedInt32Array()
	var rings := 26
	var radial := 40
	for j in range(rings+1):
		var v := float(j)/float(rings)
		var latitude := PI*v
		var s := sin(latitude)
		var y := cos(latitude)
		for k in range(radial+1):
			var phi := TAU*float(k)/float(radial)
			var x := s*cos(phi)
			var z := s*sin(phi)
			var r := 1.0
			if kind=="head":
				# Cranio largo em cima e maxilar suave em baixo.
				r = .92+.11*maxf(y,0)+.06*pow(1.0-absf(y),3)
				z*=.97+.07*maxf(-y,0)
				if y<-.5:
					r*=.91
			else:
				# Peito um pouco mais largo que a cintura, sem barriga-bola.
				r=.87+.14*maxf(y,0)+.05*maxf(-y,0)
				z*=1.0+.06*maxf(-y,0)
			var point := Vector3(x*r,y,z*r)*.5
			# Relief organico muito sutil, nao deformar o contorno.
			var relief := sin(phi*11.0+y*17.0)*sin(phi*7.0-y*9.0)*.0019
			point+=point.normalized()*relief
			uv.append(point)
	for j in range(rings):
		for k in range(radial):
			var a := j*(radial+1)+k
			var b := a+radial+1
			indexed.append_array(PackedInt32Array([a,b,a+1,b,b+1,a+1]))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in indexed:
		st.add_vertex(uv[t])
	st.generate_normals()
	return st.commit()

static func _ear(model: Node3D,side: float) -> void:
	# As duas orelhas sao conchas curvas, com espessura, frente rosada e borda.
	var mid := [
		Vector3(side*.34,1.73,.15),
		Vector3(side*.48,1.82,.10),
		Vector3(side*.63,1.92,.055),
		Vector3(side*.80,2.02,-.01),
		Vector3(side*.91,2.055,-.035)
	]
	var widths := [.075,.145,.132,.073,.002]
	for inset in [false,true]:
		var points: Array=[]
		for i in range(mid.size()-1):
			var ta: Vector3=mid[i]
			var tb: Vector3=mid[i+1]
			var wa: float=widths[i]*(.65 if inset else 1.0)
			var wb: float=widths[i+1]*(.65 if inset else 1.0)
			if inset:
				ta=ta.lerp(Vector3(side*.57,1.90,.12),.14)
				tb=tb.lerp(Vector3(side*.57,1.90,.12),.14)
				ta.z+=.014
				tb.z+=.014
			var upper_a := ta+Vector3(0,wa,0)
			var lower_a := ta-Vector3(0,wa,0)
			var upper_b := tb+Vector3(0,wb,0)
			var lower_b := tb-Vector3(0,wb,0)
			points.append_array([upper_a,lower_a,upper_b,upper_b,lower_a,lower_b])
		var material: Material=_mat(model,"orelha" if inset else "pele")
		var mesh := _surface(points)
		_piece(model,"Cabeca",("OrelhaInterna" if inset else "OrelhaExterna")+str(int(side)),
			mesh,Vector3.ZERO,Vector3.ONE,material)
	_line(model,"Cabeca","BordaOrelha"+str(int(side)),
		[mid[0]+Vector3(0,widths[0],0),mid[1]+Vector3(0,widths[1],0),
		mid[2]+Vector3(0,widths[2],0),mid[3]+Vector3(0,widths[3],0)],
		.014,_mat(model,"pele_clara"))
	_orb(model,"Cabeca","BaseOrelha"+str(int(side)),mid[0],
		Vector3(.19,.23,.16),_mat(model,"pele"))

static func _head(model: Node3D) -> void:
	_piece(model,"Cabeca","CranioEsculpido",_sculpted_mesh("head"),
		Vector3(0,1.754,-.018),Vector3(.82,.67,.60),_mat(model,"pele"))
	_orb(model,"Cabeca","MaxilarAnatomico",Vector3(0,1.505,.12),
		Vector3(.53,.235,.45),_mat(model,"pele"))
	for side in [-1.0,1.0]:
		_ear(model,side)
		var x: float=side*.182
		var suffix := "Esq" if side<0 else "Dir"
		_orb(model,"Cabeca","MacaRosto"+suffix,Vector3(side*.255,1.565,.210),
			Vector3(.215,.180,.220),_mat(model,"pele"))
		_orb(model,"Cabeca","ArcadaOcular"+suffix,Vector3(x,1.77,.270),
			Vector3(.205,.181,.110),_mat(model,"pele_sombra"))
		_orb(model,"Cabeca","Esclerotica"+suffix,Vector3(x,1.764,.331),
			Vector3(.176,.153,.118),_mat(model,"olho"))
		_orb(model,"Cabeca","AnelIris"+suffix,Vector3(x,1.762,.404),
			Vector3(.103,.108,.042),_mat(model,"couro_escuro"))
		_orb(model,"Cabeca","IrisAmbar"+suffix,Vector3(x,1.762,.413),
			Vector3(.086,.093,.041),_mat(model,"iris"))
		_orb(model,"Cabeca","PupilaNegra"+suffix,Vector3(x,1.763,.443),
			Vector3(.046,.067,.021),_mat(model,"pupila"))
		_orb(model,"Cabeca","PontoDeLuz"+suffix,
			Vector3(x-.024,1.793,.458),Vector3(.021,.024,.01),_mat(model,"luz"))
		# Palpebra expressiva entre iris e sobrancelha, angulo de irritacao.
		var upper_lid: Array=[
			Vector3(x-side*.092,1.823,.397),
			Vector3(x,1.868,.401),
			Vector3(x+side*.100,1.840,.371)
		]
		_line(model,"Cabeca","Palpebra"+suffix,upper_lid,.026,_mat(model,"pele"))
		var brow: Array=[
			Vector3(x-side*.121,1.889,.328),
			Vector3(x,1.930,.322),
			Vector3(x+side*.122,1.899,.295)
		]
		_line(model,"Cabeca","SobrancelhaMuscular"+suffix,
			brow,.040,_mat(model,"pele_sombra"))
	# Vincos leves na testa e corcova pequena em tom de osso.
	for i in range(3):
		var h := 2.006+float(i)*.033
		_line(model,"Cabeca","VincoTesta"+str(i),[
			Vector3(-.22+float(i)*.025,h,.235-float(i)*.017),
			Vector3(0,h+.013,.277-float(i)*.016),
			Vector3(.22-float(i)*.025,h,.235-float(i)*.017)
		],.008,_mat(model,"pele_sombra"))
	var horn := CylinderMesh.new()
	horn.top_radius=.008
	horn.bottom_radius=.075
	horn.height=.145
	horn.radial_segments=20
	_piece(model,"Cabeca","PequenoChifre",horn,
		Vector3(0,2.165,-.035),Vector3.ONE,_mat(model,"nariz"))
	# Ponte do nariz e ponta triangular arredondada, nao uma bola rosa.
	_orb(model,"Cabeca","PonteDoNariz",Vector3(0,1.666,.350),
		Vector3(.147,.286,.180),_mat(model,"nariz"))
	_orb(model,"Cabeca","NarizPontudo",Vector3(0,1.559,.461),
		Vector3(.226,.168,.192),_mat(model,"nariz"))
	_orb(model,"Cabeca","AbaNarizEsq",Vector3(-.092,1.55,.482),
		Vector3(.100,.093,.112),_mat(model,"nariz"))
	_orb(model,"Cabeca","AbaNarizDir",Vector3(.092,1.55,.482),
		Vector3(.100,.093,.112),_mat(model,"nariz"))
	for side in [-1.0,1.0]:
		_orb(model,"Cabeca","Narina"+str(int(side)),
			Vector3(side*.099,1.514,.556),
			Vector3(.038,.024,.016),_mat(model,"boca"))
	_line(model,"Cabeca","BocaSeria",[
		Vector3(-.206,1.462,.363),Vector3(-.103,1.456,.405),
		Vector3(0,1.459,.421),Vector3(.103,1.456,.405),
		Vector3(.206,1.462,.363)
	],.010,_mat(model,"boca"))
	_line(model,"Cabeca","LabioBaixo",[
		Vector3(-.150,1.440,.392),Vector3(0,1.427,.412),
		Vector3(.150,1.440,.392)
	],.018,_mat(model,"pele_clara"))

static func _torso(model: Node3D) -> void:
	_orb(model,"Pescoco","PescocoAnatomico",Vector3(0,1.416,-.003),
		Vector3(.223,.224,.210),_mat(model,"pele"))
	_piece(model,"Coluna","TorsoAnatomico",_sculpted_mesh("torso"),
		Vector3(0,1.14,-.013),Vector3(.603,.673,.445),_mat(model,"pele"))
	_orb(model,"Coluna","MusculoPeitoralEsq",Vector3(-.160,1.32,.174),
		Vector3(.245,.18,.180),_mat(model,"pele_clara"))
	_orb(model,"Coluna","MusculoPeitoralDir",Vector3(.160,1.32,.174),
		Vector3(.245,.18,.180),_mat(model,"pele_clara"))
	# Abdomen tem volume discreto em vez de esfera solta.
	_orb(model,"Coluna","AbdomenSuave",Vector3(0,1.035,.127),
		Vector3(.394,.323,.263),_mat(model,"pele"))
	for i in range(2):
		var y := 1.12-float(i)*.095
		_line(model,"Coluna","MarcaMusculo"+str(i),[
			Vector3(-.104,y,.253),Vector3(0,y-.014,.263),Vector3(.104,y,.253)
		],.006,_mat(model,"pele_sombra"))
	# Correias achatadas e costura visivel: nao parecem canos.
	for side in [-1.0,1.0]:
		_line(model,"Coluna","ArreioCouro"+str(int(side)),[
			Vector3(side*.290,1.385,.180),
			Vector3(side*.214,1.283,.229),
			Vector3(side*.111,1.160,.268),
			Vector3(0,1.075,.281)
		],.043,_mat(model,"couro"))
		_line(model,"Coluna","CosturaArreio"+str(int(side)),[
			Vector3(side*.286,1.385,.214),
			Vector3(side*.205,1.283,.265),
			Vector3(side*.100,1.160,.302)
		],.006,_mat(model,"ouro"))
	_orb(model,"Coluna","MedalhaoBronze",Vector3(0,1.076,.306),
		Vector3(.114,.112,.046),_mat(model,"ouro"))
	_orb(model,"Coluna","CentroMedalhao",Vector3(0,1.076,.345),
		Vector3(.053,.052,.016),_mat(model,"couro"))
	_orb(model,"Quadril","TransicaoCintura",Vector3(0,.806,-.008),
		Vector3(.477,.245,.402),_mat(model,"pele"))
	_orb(model,"Quadril","CintoAnatomico",Vector3(0,.812,.003),
		Vector3(.643,.152,.483),_mat(model,"couro_escuro"))
	# Fivela bronze com rebaixo e pino.
	_orb(model,"Quadril","BaseFivela",Vector3(0,.812,.250),
		Vector3(.210,.135,.047),_mat(model,"ouro"))
	_orb(model,"Quadril","FundoFivela",Vector3(0,.812,.291),
		Vector3(.130,.077,.018),_mat(model,"couro_escuro"))
	_line(model,"Quadril","PinoFivela",[
		Vector3(-.056,.810,.316),Vector3(.039,.810,.316)
	],.009,_mat(model,"ouro"))
	_skirt(model)

static func _skirt(model: Node3D) -> void:
	# 10 abas curvas e sobrepostas envolvendo todo o quadril.
	for segment in range(10):
		var angle := TAU*float(segment)/10.0
		var next_angle := angle+TAU*.116
		var tri: Array=[]
		var upper: Array=[]
		var lower: Array=[]
		for j in range(5):
			var t := float(j)/4.0
			var a := lerpf(angle,next_angle,t)
			var rad := .291+.018*sin(float(segment)*1.73)
			upper.append(Vector3(sin(a)*rad,.79,cos(a)*rad))
			lower.append(Vector3(sin(a)*(rad+.066),.506-.032*sin(t*PI),
				cos(a)*(rad+.080)))
		for j in range(4):
			tri.append_array([upper[j],lower[j],upper[j+1],
				upper[j+1],lower[j],lower[j+1]])
		var cloth: ArrayMesh=_surface(tri)
		_piece(model,"Quadril","SaiaCouro%d" % segment,cloth,
			Vector3.ZERO,Vector3.ONE,
			_mat(model,"saia" if segment%2==0 else "couro"))
		_line(model,"Quadril","Pesponto%d" % segment,[
			upper[0].lerp(lower[0],.10),
			upper[0].lerp(lower[0],.80)
		],.006,_mat(model,"couro_escuro"))

static func _tube_mesh(points: Array, radii: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 14
	var ring: Array=[]
	for i in range(points.size()):
		var center: Vector3=points[i]
		var tangent: Vector3
		if i==0:
			tangent=(points[1]-points[0]).normalized()
		elif i==points.size()-1:
			tangent=(points[i]-points[i-1]).normalized()
		else:
			tangent=(points[i+1]-points[i-1]).normalized()
		var axis := tangent.cross(Vector3.FORWARD).normalized()
		if axis.length_squared()<.05:
			axis=tangent.cross(Vector3.RIGHT).normalized()
		var depth := tangent.cross(axis).normalized()
		var vertex_ring: Array=[]
		for j in range(segments):
			var a := TAU*float(j)/float(segments)
			vertex_ring.append(center+float(radii[i])*(axis*cos(a)+depth*sin(a)))
		ring.append(vertex_ring)
	for i in range(ring.size()-1):
		for j in range(segments):
			var next := (j+1)%segments
			st.add_vertex(ring[i][j])
			st.add_vertex(ring[i+1][j])
			st.add_vertex(ring[i][next])
			st.add_vertex(ring[i][next])
			st.add_vertex(ring[i+1][j])
			st.add_vertex(ring[i+1][next])
	st.generate_normals()
	return st.commit()

static func _tissue(model: Node3D,bone: String,name: String,
		path: Array,radii: Array,material: Material) -> void:
	var mesh := _tube_mesh(path,radii)
	_piece(model,bone,name,mesh,Vector3.ZERO,Vector3.ONE,material)

static func _limbs(model: Node3D) -> void:
	for side in [-1.0,1.0]:
		var left: bool=side<0.0
		var suf := "Esq" if left else "Dir"
		var upper := "OmbroEsq" if left else "OmbroDir"
		var lower := "CotoveloEsq" if left else "CotoveloDir"
		var hand := "MaoEsq" if left else "MaoDir"
		var thigh := "CoxaEsq" if left else "CoxaDir"
		var knee := "JoelhoEsq" if left else "JoelhoDir"
		var ankle := "TornozeloEsq" if left else "TornozeloDir"
		var shoulder:=Vector3(.32*side,1.31,0)
		var elbow:=Vector3(.46*side,1.04,.01)
		var wrist:=Vector3(.51*side,.81,.05)
		_orb(model,upper,"Deltoide"+suf,shoulder,
			Vector3(.222,.238,.220),_mat(model,"pele"))
		_tissue(model,upper,"BracoMuscular"+suf,[
			shoulder,shoulder.lerp(elbow,.28)+Vector3(.015*side,0,0),
			shoulder.lerp(elbow,.68),elbow
		],[.115,.121,.107,.087],_mat(model,"pele"))
		_orb(model,lower,"CotoveloSuave"+suf,elbow,
			Vector3(.173,.178,.172),_mat(model,"pele"))
		_tissue(model,lower,"AntebracoMuscular"+suf,[
			elbow,elbow.lerp(wrist,.31),elbow.lerp(wrist,.77),wrist
		],[.089,.100,.083,.070],_mat(model,"pele"))
		_orb(model,hand,"Pulso"+suf,wrist,
			Vector3(.143,.151,.143),_mat(model,"pele"))
		_orb(model,hand,"BraceleteCouro"+suf,wrist+Vector3(0,-.026,0),
			Vector3(.206,.107,.202),_mat(model,"couro"))
		_orb(model,hand,"AroBracelete"+suf,wrist+Vector3(0,.028,0),
			Vector3(.199,.038,.198),_mat(model,"ouro"))
		var palm:=wrist+Vector3(.012*side,-.123,.034)
		_orb(model,hand,"PalmaAnatomica"+suf,palm,
			Vector3(.186,.224,.161),_mat(model,"pele"))
		# Dedos independentes, quatro curvos e polegar lateral.
		for f in range(4):
			var off := (float(f)-1.5)*.040
			var sx:=palm.x+off
			var base:=Vector3(sx,.682,.092)
			_tissue(model,hand,"Dedo"+suf+str(f),[
				base,base+Vector3(0,-.045,.024),
				base+Vector3(0,-.087,.035)
			],[.026,.024,.016],_mat(model,"pele"))
		_tissue(model,hand,"Polegar"+suf,[
			palm+Vector3(.073*side,.010,.05),
			palm+Vector3(.136*side,-.055,.11),
			palm+Vector3(.104*side,-.112,.14)
		],[.043,.038,.025],_mat(model,"pele"))
		var hip:=Vector3(.16*side,.76,0)
		var knee_pos:=Vector3(.17*side,.49,.01)
		var foot:=Vector3(.17*side,.21,.03)
		_orb(model,thigh,"ArticulacaoQuadril"+suf,hip,
			Vector3(.207,.224,.207),_mat(model,"pele"))
		_tissue(model,thigh,"CoxaAnatomica"+suf,[
			hip,hip.lerp(knee_pos,.25),hip.lerp(knee_pos,.75),knee_pos
		],[.140,.143,.117,.096],_mat(model,"pele"))
		_orb(model,knee,"Joelho"+suf,knee_pos,
			Vector3(.192,.184,.185),_mat(model,"pele"))
		_tissue(model,knee,"Panturrilha"+suf,[
			knee_pos,knee_pos.lerp(foot,.22),knee_pos.lerp(foot,.61),foot
		],[.100,.118,.093,.073],_mat(model,"pele"))
		_boot(model,ankle,side,suf)

static func _boot(model: Node3D,bone: String,side: float,suffix: String) -> void:
	var x:=.17*side
	_orb(model,bone,"CanoBota"+suffix,Vector3(x,.245,.022),
		Vector3(.230,.278,.238),_mat(model,"bota"))
	_orb(model,bone,"DobraBota"+suffix,Vector3(x,.348,.02),
		Vector3(.252,.088,.263),_mat(model,"couro"))
	_orb(model,bone,"Calcanhar"+suffix,Vector3(x,.104,-.016),
		Vector3(.278,.175,.260),_mat(model,"bota"))
	_orb(model,bone,"CorpoBota"+suffix,Vector3(x,.121,.148),
		Vector3(.311,.215,.462),_mat(model,"bota"))
	_orb(model,bone,"Biqueira"+suffix,Vector3(x,.119,.321),
		Vector3(.307,.151,.236),_mat(model,"couro"))
	_orb(model,bone,"SolaEscura"+suffix,Vector3(x,.047,.167),
		Vector3(.338,.060,.492),_mat(model,"sola"))
	_orb(model,bone,"BordaCouro"+suffix,Vector3(x,.348,.014),
		Vector3(.258,.049,.250),_mat(model,"couro_escuro"))
	_line(model,bone,"CosturaBota"+suffix,[
		Vector3(x-.115,.199,.291),Vector3(x,.188,.335),
		Vector3(x+.115,.199,.291)
	],.008,_mat(model,"ouro"))
	for k in range(3):
		var y := .205-float(k)*.037
		_line(model,bone,"Atacador"+suffix+str(k),[
			Vector3(x-.058,y,.213),Vector3(x+.058,y,.213)
		],.007,_mat(model,"couro_escuro"))

static func enhance(model: Node3D) -> void:
	_remove_primitive_parts(model)
	_head(model)
	_torso(model)
	_limbs(model)
	model.set_meta("acabamento_v3",2)
