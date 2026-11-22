extends RefCounted
## Golpe curto de machado em madeira: ataque seco, fibras rasgando e ressonancia grave.
## PCM 16-bit gerado uma unica vez, sem dependencia de WAV externo.

static func make_stream() -> AudioStreamWAV:
	const RATE := 22050
	const DURATION := 0.43
	var frames := int(RATE * DURATION)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 921734
	var smoothed := 0.0
	for i in range(frames):
		var t := float(i) / float(RATE)
		var noise := rng.randf_range(-1.0, 1.0)
		smoothed = lerpf(smoothed, noise, 0.25)
		var crack_env := exp(-t * 42.0)
		var split_env := exp(-pow((t - 0.062) / 0.034, 2.0))
		var wood_env := exp(-t * 13.0)
		var dry_crack := noise * crack_env * 0.54
		var fiber_split := (smoothed * 0.73 + noise * 0.27) * split_env * 0.30
		var hollow_wood := sin(TAU * (155.0 * t - 63.0 * t * t)) * wood_env * 0.36
		var low_thump := sin(TAU * 93.0 * t) * exp(-t * 20.0) * 0.22
		var scrape_env := exp(-maxf(t - 0.075, 0.0) * 19.0) if t >= 0.075 else 0.0
		var scrape := smoothed * scrape_env * 0.16
		var fade := clampf((DURATION - t) * 24.0, 0.0, 1.0)
		var sample := int(clampf((dry_crack + fiber_split + hollow_wood + low_thump + scrape) * fade, -0.94, 0.94) * 32767.0)
		data[i * 2] = sample & 255
		data[i * 2 + 1] = (sample >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
