extends RefCounted
## GOBLIN V4 - ROSTO REESCULPIDO
## Proporcoes do desenho: olhos fundos, grandes sobrancelhas organicas,
## nariz saliente, maxilar estreito, orelhas longas e conchas curvas.
## Nenhuma imagem externa ou marca d'agua e incorporada.
const RING_SEGS := 36

static func mesh_part(model: Node3D,bone: String,label: String,mesh: Mesh,mat: Material) -> MeshInstance3D:
	return model.call("_mesh_on",bone,label,mesh,Vector3.ZERO,Vector3.ZERO,Vector3.ONE,mat) as MeshInstance3D

static func oval(model: Node3D,bone: String,label: String,pos: Vector3,
		dims: Vector3,mat: Material,rot := Vector3.ZERO) -> void:
	model.call("_oval",bone,label,pos,dims,mat,rot)

static func curve(model: Node3D,bone: String,label: String,points: Array,
		width: float,material: Material) -> void:
	for i in range(points.size()-1):
		model.call("_rod",bone,label+str(i),points[i],points[i+1],width,material)

static func smooth_mesh(points: Array,cols: int,rows: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(rows-1):
		for k in range(cols-1):
			var a: Vector3=points[j*cols+k]
			var b: Vector3=points[j*cols+k+1]
			var c: Vector3=points[(j+1)*cols+k]
			var d: Vector3=points[(j+1)*cols+k+1]
			st.add_vertex(a)
			st.add_vertex(c)
			st.add_vertex(b)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(d)
	st.index()
	st.generate_normals()
	return st.commit()

static func loft_y(rings: Array,segs := 40,subdivisions := 5) -> ArrayMesh:
	var nrows := (rings.size()-1)*subdivisions+1
	var points: Array=[]
	for row in range(nrows):
		var section: int=mini(row/subdivisions,rings.size()-2)
		var t := clampf(float(row-section*subdivisions)/float(subdivisions),0,1)
		t=t*t*(3.0-2.0*t)
		var current: Vector4=rings[section]
		var next: Vector4=rings[section+1]
		var p := current.lerp(next,t)
		for seg in range(segs+1):
			var phi:=TAU*float(seg)/float(segs)
			var x:=cos(phi)*p.y
			var z:=sin(phi)*p.z+p.w
			points.append(Vector3(x,p.x,z))
	return smooth_mesh(points,segs+1,nrows)

static func ribbon(model: Node3D,bone: String,label: String,
		samples: Array,widths: Array,mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(samples.size()-1):
		var a: Vector3=samples[i]
		var b: Vector3=samples[i+1]
		var tangent: Vector3=(b-a).normalized()
		var side:=Vector3(-tangent.y,tangent.x,0).normalized()
		var ra: float=widths[i]
		var rb: float=widths[i+1]
		var al:=a-side*ra
		var ar:=a+side*ra
		var bl:=b-side*rb
		var br:=b+side*rb
		st.add_vertex(al)
		st.add_vertex(bl)
		st.add_vertex(ar)
		st.add_vertex(ar)
		st.add_vertex(bl)
		st.add_vertex(br)
	st.index()
	st.generate_normals()
	mesh_part(model,bone,label,st.commit(),mat)

static func _ear_mesh(side: float,inset: bool) -> ArrayMesh:
	# Superficie em concha 3D, curvada da base ate a ponta.
	var rows := 25
	var cols := 13
	var points: Array=[]
	for row in range(rows):
		var t:=float(row)/float(rows-1)
		var effective_t:=lerpf(.11,.92,t) if inset else t
		var reach:=pow(effective_t,.83)
		var center_x:=side*(.318+.575*reach)
		var center_y:=1.782+.295*sin(effective_t*PI*.72)
		var center_z:=.060-.122*effective_t
		var width:=.154*pow(maxf(sin(PI*effective_t),0),.83)+.015*(1.0-effective_t)
		if inset:
			width*=.70
		for col in range(cols):
			var u:=float(col)/float(cols-1)*2.0-1.0
			var y:=center_y+width*u
			var z:=center_z+.055*u*u-.020*(1.0-u*u)
			if inset:
				z+=.014
			points.append(Vector3(center_x,y,z))
	return smooth_mesh(points,cols,rows)

static func build(model: Node3D,mat: Dictionary) -> void:
	# Cranio e maxilar sao a MESMA malha de forma organica.
	var skull: Array=[
		Vector4(1.437,.012,.020,.05),
		Vector4(1.475,.148,.164,.052),
		Vector4(1.531,.232,.206,.064),
		Vector4(1.607,.307,.259,.025),
		Vector4(1.705,.351,.286,-.016),
		Vector4(1.807,.366,.288,-.030),
		Vector4(1.895,.351,.260,-.038),
		Vector4(1.984,.297,.211,-.046),
		Vector4(2.065,.204,.152,-.045),
		Vector4(2.107,.080,.072,-.040),
		Vector4(2.112,.005,.005,-.040)
	]
	mesh_part(model,"Cabeca","V4_CranioEsculpido",loft_y(skull),mat["skin"])
	# Palpebras encaixadas, sem olhos-bola soltos.
	for side in [-1.0,1.0]:
		var tag := "Esq" if side<0.0 else "Dir"
		var x: float=side*.180
		mesh_part(model,"Cabeca","V4_Orelha"+tag,_ear_mesh(side,false),mat["skin"])
		mesh_part(model,"Cabeca","V4_ConchaOrelha"+tag,_ear_mesh(side,true),mat["ear"])
		# Musculos da raiz da orelha unem o contorno ao cranio.
		oval(model,"Cabeca","V4_BaseOrelha"+tag,
			Vector3(side*.330,1.782,.023),Vector3(.147,.174,.146),mat["skin"])
		oval(model,"Cabeca","V4_SombraOrbital"+tag,
			Vector3(x,1.737,.258),Vector3(.207,.178,.080),mat["shadow"])
		oval(model,"Cabeca","V4_Olho"+tag,
			Vector3(x,1.739,.301),Vector3(.151,.134,.099),mat["white"])
		oval(model,"Cabeca","V4_Iris"+tag,
			Vector3(x,1.735,.362),Vector3(.091,.098,.046),mat["iris"])
		oval(model,"Cabeca","V4_Pupila"+tag,
			Vector3(x,1.737,.391),Vector3(.049,.071,.021),mat["dark"])
		oval(model,"Cabeca","V4_BrilhoOlho"+tag,
			Vector3(x-side*.025,1.776,.404),Vector3(.019,.024,.010),mat["white"])
		# Sobrolho musculoso e palpebra que OCULTA parte do olho.
		ribbon(model,"Cabeca","V4_Sobrancelha"+tag,[
			Vector3(x-side*.145,1.846,.283),
			Vector3(x-side*.077,1.880,.331),
			Vector3(x,1.891,.346),
			Vector3(x+side*.086,1.870,.317),
			Vector3(x+side*.138,1.833,.273)
		],[.021,.051,.065,.045,.014],mat["skin"])
		curve(model,"Cabeca","V4_Palpebra"+tag,[
			Vector3(x-side*.133,1.814,.335),
			Vector3(x-side*.058,1.832,.369),
			Vector3(x+side*.040,1.822,.379),
			Vector3(x+side*.130,1.798,.327)
		],.018,mat["skin"])
		curve(model,"Cabeca","V4_PalpebraInferior"+tag,[
			Vector3(x-side*.105,1.663,.335),
			Vector3(x,1.651,.369),
			Vector3(x+side*.096,1.678,.334)
		],.012,mat["skin_light"])
		# Sulco discreto na face, sem "bolas" nas bochechas.
		curve(model,"Cabeca","V4_RugaExpressao"+tag,[
			Vector3(side*.120,1.545,.297),
			Vector3(side*.206,1.515,.254),
			Vector3(side*.243,1.477,.199)
		],.007,mat["shadow"])
	# Ponte e ponta do nariz saem da face como uma so peça modelada.
	var nose: Array=[
		Vector4(1.735,.032,.041,.248),
		Vector4(1.681,.070,.088,.298),
		Vector4(1.631,.107,.123,.366),
		Vector4(1.574,.138,.132,.430),
		Vector4(1.537,.126,.130,.462),
		Vector4(1.513,.086,.092,.453),
		Vector4(1.505,.008,.008,.437)
	]
	mesh_part(model,"Cabeca","V4_NarizAnatomico",loft_y(nose,32,5),mat["nose"])
	for side in [-1.0,1.0]:
		oval(model,"Cabeca","V4_AsaNariz"+str(int(side)),
			Vector3(side*.105,1.535,.455),Vector3(.092,.067,.085),mat["nose"])
		oval(model,"Cabeca","V4_Narina"+str(int(side)),
			Vector3(side*.105,1.506,.510),Vector3(.035,.019,.013),mat["dark"])
	# Maxilar afilado e boca curta "resmungando".
	curve(model,"Cabeca","V4_Boca",[
		Vector3(-.157,1.465,.280),
		Vector3(-.082,1.449,.317),
		Vector3(.020,1.445,.332),
		Vector3(.105,1.454,.307),
		Vector3(.157,1.469,.277)
	],.012,mat["dark"])
	curve(model,"Cabeca","V4_LabioInferior",[
		Vector3(-.118,1.429,.300),
		Vector3(0,1.416,.328),
		Vector3(.118,1.429,.301)
	],.012,mat["skin_light"])
	# Pregas sutis na testa (nao sao tiras soltas).
	for i in range(2):
		var height:=1.965+float(i)*.040
		curve(model,"Cabeca","V4_PregaTesta"+str(i),[
			Vector3(-.198,height,.189-float(i)*.032),
			Vector3(0,height+.010,.219-float(i)*.028),
			Vector3(.198,height,.189-float(i)*.032)
		],.006,mat["shadow"])
	var horn := CylinderMesh.new()
	horn.bottom_radius=.067
	horn.top_radius=0.0
	horn.height=.152
	horn.radial_segments=20
	mesh_part(model,"Cabeca","V4_ChifreCurto",horn,mat["nose"])
	# Chifre posicionado sobre o cranio, seguindo o osso da cabeca.
	var horn_node:=model.find_children("V4_ChifreCurto","MeshInstance3D",true,false)[0] as MeshInstance3D
	var skeleton:=model.get("skeleton") as Skeleton3D
	var joint_idx:=skeleton.find_bone("Cabeca")
	horn_node.transform=skeleton.get_bone_global_rest(joint_idx).affine_inverse()*Transform3D(Basis.IDENTITY,Vector3(0,2.157,-.030))
