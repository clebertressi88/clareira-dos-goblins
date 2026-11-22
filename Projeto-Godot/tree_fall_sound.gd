extends RefCounted
## Som de queda criado em PCM 16 bits. Sem arquivo de audio externo.
## Primeiro a madeira range, depois o tronco atinge o chao e as folhas chacoalham.

static func make_stream() -> AudioStreamWAV:
	const RATE := 22050
	const DURATION := 1.7
	var count := int(float(RATE) * DURATION)
	var buffer := PackedByteArray()
	buffer.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 723181
	var low_noise := 0.0
	for index in range(count):
		var t := float(index) / float(RATE)
		var raw_noise := rng.randf_range(-1.0,1.0)
		low_noise = lerpf(low_noise,raw_noise,.17)
		var creak_envelope := clampf((t-.06)*5.0,0.0,1.0)*clampf((1.02-t)*2.6,0.0,1.0)
		var wobble := sin(TAU*(6.0*t+3.0*t*t))
		var creak := sin(TAU*(95.0*t + 36.0*t*t) + wobble*.6) * creak_envelope*.30
		var splinter := low_noise*creak_envelope*(.16+.20*absf(wobble))
		var crash_env := exp(-pow((t-1.04)/.075,2.0))
		var crash := (raw_noise*.25+low_noise*.75)*crash_env*.95
		var thud_env := exp(-maxf(t-1.05,0.0)*8.0) if t>=1.05 else 0.0
		var thud := sin(TAU*(57.0*t-9.0*t*t))*thud_env*.51
		var leaves_env := exp(-maxf(t-1.11,0.0)*4.3) if t>=1.11 else 0.0
		var leaves := raw_noise*leaves_env*.23
		var amplitude := clampf((1.7-t)*8.0,0.0,1.0)
		var mixed := clampf((creak+splinter+crash+thud+leaves)*amplitude,-.97,.97)
		var sample := int(mixed*32767.0)
		buffer[index*2] = sample & 255
		buffer[index*2+1] = (sample >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = buffer
	return stream
