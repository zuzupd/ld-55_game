extends CharacterBody3D

@export var sensitivity: float = 0.001
var mouse_motion: Vector2 = Vector2.ZERO
@export var player_speed = 5.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event) -> void:
	if event is InputEventMouseMotion:
		mouse_motion = event.relative
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var forward_dir = -transform.basis.z.normalized()
	var right_dir = transform.basis.x.normalized()

	var input_x = Input.get_action_strength("movement_right") - Input.get_action_strength("movement_left")
	var input_z = Input.get_action_strength("movement_up") - Input.get_action_strength("movement_down")
	var movement_direction = (forward_dir * input_z + right_dir * input_x).normalized()

	if movement_direction.length() > 0:
		velocity.x = movement_direction.x * player_speed
		velocity.z = movement_direction.z * player_speed
	else:
		velocity.x = move_toward(velocity.x, 0, player_speed)
		velocity.z = move_toward(velocity.z, 0, player_speed)
	handle_rotation()
	move_and_slide()

func handle_rotation() -> void:
	rotate_y(-mouse_motion.x * sensitivity)
