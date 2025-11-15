extends Control


@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var quit_button: Button = $VBoxContainer/QuitButton



func _ready() -> void:
	hide()
	close_button.hide()
	quit_button.hide()
	Server.on_lobby_clients_updated.connect(on_lobby_clients_updated)
	Server.on_cant_connect_to_lobby.connect(on_cant_connect_to_lobby)
	Server.on_lobby_locked.connect(on_lobby_locked)
	
func activate():
	if Server.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		status_label.text = "Connecting..."
		show()
	else:
		status_label.text = "You are offline"
		close_button.show()
		show()

func on_lobby_clients_updated(connected_clients: int, max_clients: int):
	status_label.text = "Waiting for players: %d/%d" % [connected_clients, max_clients]
	quit_button.show()
	
func on_cant_connect_to_lobby():
	status_label.text = "Server is full. Try again later"
	close_button.show()

func on_lobby_locked():
	status_label.text = "Game starting..."
	close_button.hide()
	quit_button.hide()

func _on_close_button_pressed() -> void:
	hide()

func _on_quit_button_pressed() -> void:
	Server.c_quit_wait_on_lobby.rpc_id(1)
	hide()
