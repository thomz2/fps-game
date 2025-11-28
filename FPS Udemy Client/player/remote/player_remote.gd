extends CharacterBody3D
class_name PlayerRemote

const ANIM_BLEND_TIME := 0.2 

@onready var head: Node3D = $Head
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var current_animation := "Idle_Shoot"

func set_anim(anim_name: String):
	if animation_player.assigned_animation == anim_name:
		return
		
	animation_player.play(anim_name, ANIM_BLEND_TIME)
