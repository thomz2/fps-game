@tool
extends Node3D
class_name PlayerSpawnPoint

func _ready() -> void:
	if Engine.is_editor_hint():
		if get_child_count() > 0:
			return

		# Adiciona scene
		add_child(load("res://player/spawn_point/player_spawn_point_arrow.tscn").instantiate())
		
		return
	queue_free()
