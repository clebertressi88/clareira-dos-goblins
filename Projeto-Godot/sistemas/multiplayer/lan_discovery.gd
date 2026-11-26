extends RefCounted
## Descoberta LAN por consulta broadcast e resposta unicast. Sem servidor externo.
const DISCOVERY_PORT := 24651
const MAGIC := "clareira-lan-v1"
const INTERVAL_MS := 1500
const EXPIRY_MS := 5500
var socket := PacketPeerUDP.new()
var mode := ""
var next_query := 0
var scan_started := 0
var nonce := ""
var rooms: Dictionary = {}
var status := ""

func stop() -> void:
	socket.close()
	mode = ""
	rooms.clear()
	status = ""

func _start(wanted: String) -> void:
	stop()
	mode = wanted
	var port := DISCOVERY_PORT if wanted=="host" else 0
	var err := socket.bind(port,"0.0.0.0")
	if err!=OK:
		status = "Descoberta indisponível. Use o IP manual."
		return
	socket.set_broadcast_enabled(true)
	nonce = Crypto.new().generate_random_bytes(12).hex_encode()
	next_query = 0
	scan_started = Time.get_ticks_msec()

func refresh() -> void:
	rooms.clear()
	next_query = 0
	scan_started = Time.get_ticks_msec()
	if not socket.is_bound():
		mode = ""

func tick(wanted: String, protocol: int, game_port: int, world_name: String, players: int) -> void:
	if wanted!=mode:
		if wanted.is_empty():
			stop()
		else:
			_start(wanted)
	if not socket.is_bound():
		return
	var now := Time.get_ticks_msec()
	if mode=="scan" and now>=next_query:
		next_query = now+INTERVAL_MS
		if socket.set_dest_address("255.255.255.255",DISCOVERY_PORT)==OK:
			var err := socket.put_packet(JSON.stringify({"magic":MAGIC,"type":"query","nonce":nonce}).to_utf8_buffer())
			if err!=OK:
				status = "Busca LAN indisponível. Use o IP manual."
			else:
				status = ""
	for i in range(mini(socket.get_available_packet_count(),32)):
		var bytes := socket.get_packet()
		var ip := socket.get_packet_ip()
		var port := socket.get_packet_port()
		if bytes.size()>1024 or not ip.is_valid_ip_address() or ip.contains(":"):
			continue
		var parsed = JSON.parse_string(bytes.get_string_from_utf8())
		if not parsed is Dictionary:
			continue
		var data: Dictionary = parsed
		if data.get("magic","")!=MAGIC:
			continue
		if mode=="host" and data.get("type","")=="query":
			var token := str(data.get("nonce",""))
			if token.length()!=24 or port<=0:
				continue
			if socket.set_dest_address(ip,port)==OK:
				socket.put_packet(JSON.stringify({"magic":MAGIC,"type":"room","nonce":token,"protocol":protocol,"port":game_port,"world":world_name.left(64),"players":clampi(players,1,8)}).to_utf8_buffer())
		elif mode=="scan" and data.get("type","")=="room" and data.get("nonce","")==nonce and port==DISCOVERY_PORT:
			if data.get("protocol",-1)!=protocol or data.get("port",0)!=game_port:
				continue
			var name := str(data.get("world","Mundo")).left(64).replace("\n"," ").replace("\r"," ").strip_edges()
			var count = data.get("players",0)
			if not (count is int or count is float):
				continue
			rooms[ip] = {"ip":ip,"world":name if not name.is_empty() else "Mundo","players":clampi(int(count),1,8),"seen":now}
	for ip in rooms.keys():
		if now-int(rooms[ip]["seen"])>EXPIRY_MS:
			rooms.erase(ip)

func display_status() -> String:
	if not status.is_empty():
		return status
	if rooms.is_empty() and Time.get_ticks_msec()-scan_started>3500:
		return "Nenhuma partida encontrada. A busca continua automaticamente."
	return ""

func list_rooms() -> Array:
	var result: Array = []
	var ips := rooms.keys()
	ips.sort()
	for ip in ips:
		var room: Dictionary = rooms[ip]
		result.append({"ip":ip,"world":room["world"],"players":room["players"]})
	return result
