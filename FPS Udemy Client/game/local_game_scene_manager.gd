extends Node

func _ready() -> void:
	change_scene("res://ui/main_menu/main_menu.tscn")
	
func change_scene(path: String):
	clear_scenes()
	add_child(load(path).instantiate())

func clear_scenes():
	for sc in get_children(true):
		sc.queue_free()
