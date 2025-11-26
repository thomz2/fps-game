extends Node3D
class_name Lobby

var players := {}
var current_world_state : Dictionary

func get_local_player() -> PlayerLocal:
	return players.get(multiplayer.get_unique_id())
	
func get_remote_players() -> Dictionary:
	var remote_players := {}
	var local_player_id = multiplayer.get_unique_id()
	
	for player_id in players.keys():
		if player_id == local_player_id:
			continue
		
		var maybe_remote_player = players.get(player_id)
		if is_instance_valid(maybe_remote_player):
			remote_players[player_id] = maybe_remote_player
	
	return remote_players 

# Quando o OBJETO lobby é criado na parte do cliente, avisa ao servidor que o cliente está lockado
func _ready():
	c_lock_client.rpc_id(1)
	print("comunicação de lock enviada")
	set_physics_process(false)
	
func _physics_process(delta: float) -> void:
	send_player_state()
	handle_world_state()
	
func send_player_state():
	var local_player = get_local_player()
	if local_player == null:
		return
	
	var player_data = create_player_data(local_player) 
	c_send_player_state.rpc_id(1, player_data)

func handle_world_state():
	var remote_players := get_remote_players()
	if !current_world_state["ps"]:
		return
	
	for player_id in current_world_state.ps.keys():
		if player_id not in remote_players.keys():
			continue
		
		var remote_player = remote_players.get(player_id)
		var data: Dictionary = current_world_state["ps"][player_id]
		remote_player.position = data["pos"]
		remote_player.rotation.y = data["rot_y"]
		#remote_player.head.rotation.x = data["rot_x"]
		
func create_player_data(local_player: PlayerLocal):
	return {
		"pos": local_player.position,
		"rot_y": local_player.rotation.y,
		"rot_x": local_player.head.rotation.x,
		"anim": local_player.current_animation,
		#"team": local_player.team
	}

func map_ready():
	c_map_ready.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func c_map_ready():
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_lock_client():
	pass

@rpc("authority", "call_remote", "reliable")
func s_start_loading_map():
	var map = load("res://maps/map_farm.tscn").instantiate()
	map.name = "Map"
	map.ready.connect(map_ready)
	add_child(map, true)
	get_tree().call_group("LocalGameSceneManager", "clear_scenes")

@rpc("authority", "call_remote", "reliable")
func s_start_match():
	get_tree().call_group("PlayerLocal", "set_processes", true)
	set_physics_process(true)

@rpc("authority", "call_remote", "reliable")
func s_spawn_player(client_id: int, spawn_tform: Transform3D, team: int):
	var player
		
	if client_id == multiplayer.get_unique_id():
		player = preload("res://player/local/player_local.tscn").instantiate()
	else:
		player = preload("res://player/remote/player_remote.tscn").instantiate()
	
	print("player ", client_id, " renderizado!")
	
	player.name = str(client_id)
	player.global_transform = spawn_tform
	add_child(player, true)
	players[client_id] = player

@rpc("any_peer",  "call_remote", "unreliable_ordered")
func c_send_player_state(player_state: Dictionary):
	pass
	
@rpc("authority",  "call_remote", "unreliable_ordered")
func s_send_world_state(world_state: Dictionary):
	current_world_state = world_state
