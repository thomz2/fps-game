extends Control



func _on_play_button_pressed() -> void:
	# Podemos chamar assim pois o script do Server está no autoload
	Server.try_connect_client_to_lobby()
	$QuickplayConnectionUI.activate()

func _on_exit_button_pressed() -> void:
	get_tree().quit()
