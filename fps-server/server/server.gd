extends Node

# 1024 - 49000
# wikipedia list of tcp and udp ports
const PORT := 7777
const MAX_CLIENTS := 64
const MAX_LOBBIES := 2
const MAX_PLAYERS_PER_LOBBY := 2
const DISTANCE_BETWEEN_LOBBY := 100 # metros

var peer := ENetMultiplayerPeer.new()

var lobbies: Array[Lobby] = []
var idle_clients: Array[int] = []

var lobby_spots: Array[Lobby] = [] 

func _ready() -> void:
	lobby_spots.resize(MAX_LOBBIES)
	
	var error := peer.create_server(PORT, MAX_CLIENTS)
	
	if error != OK:
		print("failed to start server")
		return
	
	print("server started!")
	
	multiplayer.multiplayer_peer = peer
	
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)

# =========== observers ===========
func _on_peer_connected(id: int):
	idle_clients.append(id)
	print("client %d connected to server" % id)

func _on_peer_disconnected(id: int):
	remove_player_from_lobby_and_idle(id)

func on_client_added_on_lobby(c_id, lobby : Lobby):
	print("client %d connected to lobby %s" %[c_id, lobby.name])
	lobby_clients_updated(lobby)

func on_client_removed_from_lobby(c_id, lobby):
	if lobby.clients.is_empty():
		lobbies.erase(lobby)
		lobby.queue_free()
	else:
		lobby.status = Lobby.IDLE
	lobby_clients_updated(lobby)
	print("client %d DISconnected from lobby %s" %[c_id, lobby.name])

# =========== functions ===========
func add_lobby(lobby: Lobby) -> Lobby:
	lobbies.append(lobby)
	lobby.name = "lobby_" + str(lobby.get_instance_id())
	add_child(lobby)
	update_lobby_spots()
	return lobby

func get_lobby_from_client(id: int) -> Lobby:
	for lobby in lobbies:
		if lobby.clients.has(id):
			return lobby
	return null

func remove_player_from_lobby(id: int) -> Lobby:
	var lobby = get_lobby_from_client(id)
	if lobby == null:
		print("erro ao remover player %d do lobby, lobby nao encontrado" % id)
		return null
	lobby.remove_client(id)
	print("Player %d removido apenas do lobby %s" % [id, lobby.name])
	return lobby

func remove_player_from_lobby_and_idle(id: int):
	var maybe_lobby = get_lobby_from_client(id)
	if maybe_lobby == null:
		idle_clients.erase(id)
		return
	maybe_lobby.remove_client(id)
	print("client %d DISconnected from server" % id)

func get_non_full_lobby() -> Lobby:
	for lobby in lobbies:
		if lobby.clients.size() < MAX_PLAYERS_PER_LOBBY and lobby.status == Lobby.IDLE:
			return lobby
	
	# Aqui é criado o lobby
	if lobbies.size() < MAX_LOBBIES:
		var new_lobby := Lobby.new()
		return add_lobby(new_lobby)
	
	print("lobbies full")
	
	return null

func lobby_clients_updated(lb: Lobby):
	for client_id in lb.clients:
		s_lobby_clients_updated.rpc_id(client_id, lb.clients.size(), MAX_PLAYERS_PER_LOBBY)
	if lb.clients.size() == MAX_PLAYERS_PER_LOBBY:
		lock_lobby(lb)

func update_lobby_spots():
	# deleting unused lobby spots
	for i in range(lobby_spots.size()):
		if lobby_spots[i] != null and not lobby_spots[i] in lobbies:
			lobby_spots[i] = null

	# inserting new lobbies
	for lobby in lobbies:
		if lobby in lobby_spots:
			continue
		
		for i in range(lobby_spots.size()):
			if lobby_spots[i] == null:
				lobby_spots[i] = lobby
				lobby.global_position.y = DISTANCE_BETWEEN_LOBBY * i
				print("lobby spots atualmente: ", lobby_spots)
				print("nova posicao: ", lobby.global_position.y)
				break

func lock_lobby(lobby: Lobby):
	lobby.status = Lobby.LOCKED
	create_lobby_on_clients(lobby)

func create_lobby_on_clients(lobby : Lobby):
	for lb_client_id in lobby.clients:
		s_create_lobby_on_clients.rpc_id(lb_client_id, lobby.name)

# =========== RPCs ===========
# em remote calls, colocar de onde vem a chamada de funcao:
# c -> client ; s -> server
@rpc("any_peer", "call_remote", "reliable")
func c_try_connect_client_to_lobby() -> void:
	var client_id := multiplayer.get_remote_sender_id()
	var maybe_lobby := get_non_full_lobby()
	
	print("tentando conectar %d a algum lobby" % client_id)
	
	if maybe_lobby:
		print("lobby encontrado: %s" % maybe_lobby.name)
		
		# conectando os sinais
		maybe_lobby.on_client_added_on_lobby.connect(on_client_added_on_lobby)
		maybe_lobby.on_client_removed_from_lobby.connect(on_client_removed_from_lobby)
		
		maybe_lobby.add_client(client_id)
		idle_clients.erase(client_id)
		
		return

	print("Nao foi possivel conectar o %d a nenhum lobby" % client_id)
	# Logic when lobbies are full and client tries to connect to one
	s_client_cant_connect_to_lobby.rpc_id(client_id)
	
@rpc("any_peer", "call_remote", "reliable")
func c_quit_wait_on_lobby():
	var client_id := multiplayer.get_remote_sender_id()
	var lobby = remove_player_from_lobby(client_id)
	lobby_clients_updated(lobby)
	if lobby.clients.is_empty():
		lobbies.erase(lobby)
		lobby.queue_free()
		update_lobby_spots()

@rpc("authority", "call_remote", "reliable")
func s_lobby_clients_updated(qtd_connected_clients: int, max_clients: int):
	pass
	
@rpc("authority", "call_remote", "reliable")
func s_client_cant_connect_to_lobby():
	pass
	
@rpc("authority", "call_remote", "reliable")
func s_create_lobby_on_clients(lobby_name: String):
	pass
