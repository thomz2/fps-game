extends CharacterBody3D
class_name PlayerLocal

const IDLE_ANIM := "Idle"
const AIR_ANIM := "Jump_Idle"
const WALK_ANIM := "Walk_Shoot"
const RUN_ANIM := "Run_Shoot"

@export var normal_speed := 3.0
@export var sprint_speed := 5.0
@export var jump_velocity := 4.0
@export var gravity := 0.2
@export var mouse_sensitivity := 0.005

@onready var head: Node3D = $Head


var is_grounded := true
var is_sprinting := false
var current_animation := "Idle_Shoot"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_processes(false)


func _physics_process(delta: float) -> void:
	move()
	update_animation()

func update_animation():
	if is_grounded and (velocity.x != 0 or velocity.z != 0):
		current_animation = WALK_ANIM if !is_sprinting else RUN_ANIM 
		return
		
	if !is_grounded:
		current_animation = AIR_ANIM
		return
	
	current_animation = IDLE_ANIM
	return 

func set_processes(enabled):
	set_process(enabled)
	set_physics_process(enabled)
	set_process_input(enabled)

func move():
	if is_on_floor():
		is_sprinting = Input.is_action_pressed("sprint")
	
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	
		if not is_grounded:
			is_grounded = true
	
	else:
		velocity.y -= gravity
	
		if is_grounded:
			is_grounded = false
	
	var speed := normal_speed if not is_sprinting else sprint_speed
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity.z = direction.z * speed
	velocity.x = direction.x * speed
	
	move_and_slide()


func _input(event) -> void:
	if event is InputEventMouseMotion:
		look_around(event.relative)


func look_around(relative:Vector2):
	rotate_y(-relative.x * mouse_sensitivity)
	head.rotate_x(-relative.y * mouse_sensitivity)
	head.rotation.x = clampf(head.rotation.x, -PI/2, PI/2)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
