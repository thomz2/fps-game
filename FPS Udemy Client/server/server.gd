extends Node

signal on_lobby_clients_updated(connected_clients: int, max_clients: int)
signal on_cant_connect_to_lobby
signal on_lobby_locked

const PORT := 7777
# Por enquanto tá na mesma máquina
const ADDRESS := "127.0.0.1"

var peer := ENetMultiplayerPeer.new()

func _ready() -> void:
	
	# no projeto do server, temos create_server(...)
	var error := peer.create_client(ADDRESS, PORT)
	
	if error != OK:
		print("failed to connect to server")
		return
	
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
func _on_connected_to_server():
	print("connected to server")
	
func _on_connection_failed():
	print("failed to connect to server")
	
func try_connect_client_to_lobby():
	# O server sempre terá peer_id = 1
	c_try_connect_client_to_lobby.rpc_id(1)

# Por regra temos que deixar a função definida no outro projeto aqui também, mas a lógica fica lá
@rpc("any_peer", "call_remote", "reliable")
func c_try_connect_client_to_lobby() -> void:
	pass
	
# server vai chamar uma funcao que é executada no cliente (aqui)
@rpc("authority", "call_remote", "reliable")
func s_lobby_clients_updated(connected_clients: int, max_clients: int) -> void:
	on_lobby_clients_updated.emit(connected_clients, max_clients)
	
@rpc("authority", "call_remote", "reliable")
func s_client_cant_connect_to_lobby() -> void:
	on_cant_connect_to_lobby.emit()
	
@rpc("any_peer", "call_remote", "reliable")
func c_quit_wait_on_lobby():
	pass

# Pode ser confuso a ideia de criar um lobby para cada cliente, porém o que estamos criando é o objeto
# lobby e não o lobby em si, tanto que o lobby em si é definido pelo name dele
@rpc("authority", "call_remote", "reliable")
func s_create_lobby_on_clients(lobby_name):
	var lobby := Lobby.new()
	lobby.name = lobby_name
	add_child(lobby, true)
	on_lobby_locked.emit()
