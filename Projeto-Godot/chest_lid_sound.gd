extends RefCounted
## Sons originais gerados em PCM: rangido da dobradica na abertura
## e impacto seco, pesado, de uma tampa de madeira ao fechar.
static func make_stream(opening: bool) -> AudioStreamWAV:
	const RATE := 22050
	var duration := 0.48 if opening else 0.36
	var frames := int(float(RATE)*duration)
	var pcm := PackedByteArray()
	pcm.resize(frames*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 331003 if opening else 118772
	var smooth := 0.0
	for i in range(frames):
		var t := float(i)/float(RATE)
		var noise := rng.randf_range(-1.0,1.0)
		smooth = lerpf(smooth,noise,0.11 if opening else 0.28)
		var sample := 0.0
		if opening:
			# Atrito crescente da dobradica, madeira rangendo e dois cliques mecanicos.
			var movement := sin(PI*clampf(t/duration,0.0,1.0))
			var creak := sin(TAU*(245.0*t+24.0*t*t))*sin(TAU*8.0*t+0.4)
			var low := sin(TAU*(110.0*t+10.0*sin(TAU*2.2*t)))
			var click1 := exp(-pow((t-0.045)/0.014,2.0))
			var click2 := exp(-pow((t-0.345)/0.018,2.0))
			sample = creak*movement*0.31+low*movement*0.13+smooth*movement*0.26+(noise*0.29+low*0.15)*(click1+click2*0.55)
		else:
			# Batida frontal: estalo de madeira, ressonancia grave e vibracao final.
			var snap := exp(-t*61.0)
			var bass := exp(-t*18.0)
			var rattle := exp(-pow((t-0.062)/0.024,2.0))
			var body := sin(TAU*(115.0*t-36.0*t*t))
			sample = noise*snap*0.58+body*bass*0.48+smooth*bass*0.24+(noise*0.27+sin(TAU*310.0*t)*0.12)*rattle
		var fade := clampf((duration-t)*22.0,0.0,1.0)
		var value := int(clampf(sample*fade,-0.95,0.95)*32767.0)
		pcm[i*2] = value & 255
		pcm[i*2+1] = (value>>8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = pcm
	return stream
