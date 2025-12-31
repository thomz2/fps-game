extends CharacterBody3D
class_name PlayerLocal

const IDLE_ANIM := "Idle"
const AIR_ANIM := "Jump_Idle"
const WALK_ANIM := "Walk_Shoot"
const RUN_ANIM := "Run_Shoot"

# Configurações do Wall Run
const WALL_RUN_GRAVITY = 4.0
var wall_jump_force = 10.0
const TILT_AMOUNT = 0.15 # Radianos (aprox 8 graus)
const TILT_SPEED = 5.0

@export var normal_speed := 3.0
@export var sprint_speed := 5.0
@export var jump_velocity := 5.2
@export var gravity := 0.2
@export var mouse_sensitivity := 0.005

@onready var head: Node3D = $Head
@onready var wall_check_right: RayCast3D = $WallCheckRight
@onready var wall_check_left: RayCast3D = $WallCheckLeft

var current_tilt := 0.0

var direction
var input_dir
var speed

var is_grounded := true
var is_sprinting := false
var is_wall_running := false
var is_wall_runnable := false
var is_jumping_from_wall := false

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

var wall_run_delay_counter := 0.0
func move(delta: float):
	speed     = normal_speed if not is_sprinting else sprint_speed
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if not is_wall_running:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		is_grounded = true
		is_wall_running = false
		is_wall_runnable = true
		is_jumping_from_wall = false
		wall_run_delay_counter = 0.0
		wall_jump_force = 10.0
		
		current_tilt = lerp(current_tilt, 0.0, delta * TILT_SPEED)
		is_sprinting = Input.is_action_pressed("sprint")
		
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			
	else:
		is_grounded = false
		wall_run(delta)
		
		if not is_wall_running:
			velocity.y -= gravity
			current_tilt = lerp(current_tilt, 0.0, delta * TILT_SPEED)
			wall_run_delay_counter = 0.0
	
	if is_wall_running and wall_run_delay_counter >= 0.2:
		var dir_without_y = Vector3(direction.x, 0.0, direction.z)
		var wall_forward = dir_without_y - dir_without_y.project(wall_normal)
		direction = wall_forward.normalized()
		velocity.x = wall_forward.x * speed
		velocity.z = wall_forward.z * speed
		velocity.y = -0.35
	elif is_jumping_from_wall:
		# Se acabou de pular da parede, usamos LERP para não matar o impulso
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	else:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	head.rotation.z = -1 * current_tilt
	
	move_and_slide()

var tilt_dir
var wall_normal
func is_wallcolliding_on_side():
	if wall_check_right.is_colliding():
		wall_normal = wall_check_right.get_collision_normal()
		tilt_dir = -1
		return true
	elif wall_check_left.is_colliding():
		wall_normal = wall_check_left.get_collision_normal()
		tilt_dir = 1
		return true
	return false

func wall_run(delta):
	var condicoes_de_wallrun = Input.is_action_pressed("sprint") \
								and Input.is_action_pressed("move_forward") \
								and is_wallcolliding_on_side() \
								and is_wall_runnable
	if condicoes_de_wallrun:
		is_wall_running = true # Ativa antes para nao resetar contador
		
		# Espera um pouco antes de grudar na parede
		wall_run_delay_counter += delta
		if wall_run_delay_counter < 0.2: return
		
		current_tilt = lerp(current_tilt, TILT_AMOUNT * tilt_dir, delta * TILT_SPEED)
		
		if Input.is_action_just_pressed("jump"):
			var jump_dir = (wall_normal * 1.2 + Vector3.UP).normalized()
			velocity = jump_dir * wall_jump_force
			wall_jump_force -= wall_jump_force / 3.5
			is_wall_running = false
			is_wall_runnable = true
			is_jumping_from_wall = true 
			wall_run_delay_counter = 0.1
	else:
		is_wall_running = false

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
