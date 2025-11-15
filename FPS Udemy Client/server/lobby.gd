extends Node3D
class_name Lobby

# Quando o OBJETO lobby é criado na parte do cliente, avisa ao servidor que o cliente está lockado
func _ready():
	c_lock_client.rpc_id(1)
	print("comunicação de lock enviada")
	
@rpc("any_peer", "call_remote", "reliable")
func c_lock_client():
	pass

@rpc("authority", "call_remote", "reliable")
func s_start_loading_map():
	var map = load("res://maps/map_farm.tscn").instantiate()
	map.name = "Map"
	add_child(map, true)
	get_tree().call_group("LocalGameSceneManager", "clear_scenes")
