extends Node

var players: Array[AudioStreamPlayer] = []
var active := 0
var current := ""
var fade: Tween
var exploration_index := 0
const TRACKS = {"explore": "res://music/clareira_exploracao.ogg", "day": "res://music/amanhecer.ogg", "night": "res://music/floresta_noturna.ogg", "combat": "res://music/combate_goblin.ogg"}

func _ready() -> void:
	for i in range(2):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
		p.finished.connect(_finished.bind(i))
	play_mode("explore")

func play_mode(mode: String) -> void:
	if mode == current or not TRACKS.has(mode):
		return
	var stream := load(TRACKS[mode]) as AudioStreamOggVorbis
	if stream == null:
		return
	stream.loop = mode == "night" or mode == "combat"
	if fade and fade.is_valid():
		fade.kill()
	var old := players[active]
	active = 1 - active
	var next := players[active]
	next.stop()
	next.stream = stream
	next.volume_db = -60.0
	next.play()
	current = mode
	var target := 0.4 if mode == "combat" else (0.2 if mode == "night" else 0.25)
	fade = create_tween().set_parallel(true)
	fade.tween_property(next, "volume_db", linear_to_db(target), 3.0)
	fade.tween_property(old, "volume_db", -60.0, 3.0)
	fade.chain().tween_callback(old.stop)

func _finished(index: int) -> void:
	if index == active and current in ["explore", "day"]:
		play_mode("day" if current == "explore" else "explore")
