extends Node3D
class_name Lobby

enum {
	IDLE,
	LOCKED
}

var status := IDLE

var clients : Array[int] = []
var ready_clients : Array[int] = []

signal on_client_added_on_lobby(client_id: int, lobby: Lobby)
signal on_client_removed_from_lobby(client_id: int, lobby: Lobby)

func add_client(id: int) -> void:
	clients.append(id)
	on_client_added_on_lobby.emit(id, self)
	
func remove_client(id: int) -> void:
	if clients.has(id):
		print("player %d removed from lobby %s" %[id, self.name])
		clients.erase(id)
		on_client_removed_from_lobby.emit(id, self)

func start_loading_map():
	var map := Node3D.new()
	map.name = "Map"
	add_child(map, true)
	
	for client in ready_clients:
		s_start_loading_map.rpc_id(client)
	

@rpc("any_peer", "call_remote", "reliable")
func c_lock_client():
	var client_id := multiplayer.get_remote_sender_id()
	print("Cliente lockado:", client_id)
	
	if client_id not in clients:
		return
	
	if client_id not in ready_clients:
		ready_clients.append(client_id)
	
	if ready_clients.size() != clients.size():
		return
	
	start_loading_map()
	ready_clients.clear()

@rpc("authority", "call_remote", "reliable")
func s_start_loading_map():
	pass

@rpc("authority", "call_remote", "reliable")
func s_start_match():
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_map_ready():
	var client_id := multiplayer.get_remote_sender_id()
	
	if client_id not in clients:
		return
	
	if client_id not in ready_clients:
		ready_clients.append(client_id)
	
	if ready_clients.size() != clients.size():
		return
	
	for ready_client_id in ready_clients:
		s_start_match.rpc_id(ready_client_id)
	ready_clients.clear()
