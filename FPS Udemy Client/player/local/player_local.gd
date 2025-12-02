extends CharacterBody3D
class_name PlayerLocal

const IDLE_ANIM := "Idle"
const AIR_ANIM := "Jump_Idle"
const WALK_ANIM := "Walk_Shoot"
const RUN_ANIM := "Run_Shoot"

# Configurações do Wall Run
const WALL_RUN_GRAVITY = 4.0
const WALL_JUMP_FORCE = 8.0
const TILT_AMOUNT = 0.15 # Radianos (aprox 8 graus)
const TILT_SPEED = 5.0

@export var normal_speed := 3.0
@export var sprint_speed := 5.0
@export var jump_velocity := 4.0
@export var gravity := 0.2
@export var mouse_sensitivity := 0.005

@onready var head: Node3D = $Head
@onready var wall_check_right: RayCast3D = $WallCheckRight
@onready var wall_check_left: RayCast3D = $WallCheckLeft

var current_tilt := 0.0

var is_grounded := true
var is_sprinting := false
var current_animation := "Idle_Shoot"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_processes(false)


func _physics_process(delta: float) -> void:
	move(delta)
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

func move(delta: float):
	if is_on_floor():
		is_sprinting = Input.is_action_pressed("sprint")
		current_tilt = lerp(current_tilt, 0.0, delta * TILT_SPEED)
	
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	
		if not is_grounded:
			is_grounded = true
	
	else:
		if is_grounded:
			is_grounded = false
		
		var is_wall_running = false
		if velocity.length() > 3.5:
			if wall_check_right.is_colliding():
				process_wall_run(delta, -1) # -1 -> inclina p/ esquerda
				is_wall_running = true
			if wall_check_left.is_colliding():
				process_wall_run(delta, 1) # 1 -> inclina p/ direita
				is_wall_running = true
		if not is_wall_running:
			velocity.y -= gravity
			current_tilt = lerp(current_tilt, 0.0, delta * TILT_SPEED)
	
	var speed := normal_speed if not is_sprinting else sprint_speed
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity.z = direction.z * speed
	velocity.x = direction.x * speed
	head.rotation.z = current_tilt
	
	move_and_slide()


func process_wall_run(delta, tilt_dir):
	if velocity.y < -1.0:
		velocity.y = move_toward(velocity.y, -1.0, delta * 10)
	else:
		velocity.y -= WALL_RUN_GRAVITY * delta
	
	current_tilt = lerp(current_tilt, TILT_AMOUNT * tilt_dir, delta * TILT_SPEED)
	
	if Input.is_action_just_pressed("jump"):
		var wall_normal = Vector3.ZERO
		if tilt_dir == -1:
			wall_normal = wall_check_right.get_collision_normal()
		else:
			wall_normal = wall_check_left.get_collision_normal()
			
		velocity = (wall_normal * 1.5 + Vector3.UP).normalized() * WALL_JUMP_FORCE


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
