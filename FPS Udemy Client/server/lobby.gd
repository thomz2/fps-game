extends Node3D
class_name Lobby

# Quando o OBJETO lobby é criado na parte do cliente, avisa ao servidor que o cliente está lockado
func _ready():
	c_lock_client.rpc_id(1)
	print("comunicação de lock enviada")

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
