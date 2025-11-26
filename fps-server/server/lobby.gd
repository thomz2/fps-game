extends Node3D
class_name Lobby

var world_state := {
	"ps": {}
}

enum {
	IDLE,
	LOCKED
}

var status := IDLE

var clients : Array[int] = []
var ready_clients : Array[int] = []

signal on_client_added_on_lobby(client_id: int, lobby: Lobby)
signal on_client_removed_from_lobby(client_id: int, lobby: Lobby)

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	for client_id in clients:
		s_send_world_state.rpc_id(client_id, world_state)

func add_client(id: int) -> void:
	clients.append(id)
	on_client_added_on_lobby.emit(id, self)
	
func remove_client(id: int) -> void:
	if clients.has(id):
		print("player %d removed from lobby %s" %[id, self.name])
		clients.erase(id)
		on_client_removed_from_lobby.emit(id, self)

func start_loading_map():
	#var map := Node3D.new()
	var map = load("res://maps/server_map_farm.tscn").instantiate()
	map.name = "Map"
	add_child(map, true)
	
	for client in ready_clients:
		s_start_loading_map.rpc_id(client)
	
func spawn_players():
	var spawn_points = get_tree().get_nodes_in_group("SpawnPoints")
	var blue_sps: Array[Node3D] = []
	var red_sps: Array[Node3D]  = []
	
	for sp in spawn_points:
		if sp.name.begins_with("Red"):
			red_sps.append(sp)
		elif sp.name.begins_with("Blue"):
			blue_sps.append(sp)
	
	ready_clients.shuffle()
	
	for i in ready_clients.size():
		var team := 0
		var spawn_tform := Transform3D.IDENTITY
		
		if i % 2 == 0:
			team = 0
			spawn_tform = blue_sps[0].transform
			blue_sps.pop_front()
		
		else:
			team = 1
			spawn_tform = red_sps[0].transform
			red_sps.pop_front()
	
		var player : CharacterBody3D = preload("res://player/player_server.tscn").instantiate()
		player.name = str(ready_clients[i])
		player.global_transform = spawn_tform
		add_child(player, true)
		
		# Avisar a todos os jogadores, que o jogador atual (ready_clients[i]) foi carregado no servidor
		for ready_client_id in ready_clients:
			s_spawn_player.rpc_id(ready_client_id, ready_clients[i], spawn_tform, team)

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
	
	spawn_players()
	
	for ready_client_id in ready_clients:
		s_start_match.rpc_id(ready_client_id)
	ready_clients.clear()
	set_physics_process(true)

@rpc("authority", "call_remote", "reliable")
func s_spawn_player(client_id: int, spawn_tform: Transform3D, team: int) -> void:
	pass
	
@rpc("any_peer",  "call_remote", "unreliable_ordered")
func c_send_player_state(player_state: Dictionary):
	world_state.ps[multiplayer.get_remote_sender_id()] = player_state

@rpc("authority",  "call_remote", "unreliable_ordered")
func s_send_world_state(world_state: Dictionary):
	pass
