extends Node

func _ready() -> void:
	change_scene("res://ui/main_menu/main_menu.tscn")
	
func change_scene(path: String):
	clear_scenes()
	add_child(load(path).instantiate())

func clear_scenes():
	for sc in get_children(true):
		sc.queue_free()
		
# Nesse código, basicamente começamos com a scene do main_menu (jogador abre o jogo)
# e depois, quando o mapa for carregado, excluimos as scenes de dentro desse manager
# (scenes de menu), ficando somente as scenes de lobby e de mapa no jogo.
