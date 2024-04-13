extends CharacterBody3D

@export var sensitivity: float = 0.001
@export var deadzone: float = 0.001
var mouse_motion: Vector2 = Vector2.ZERO
@export var player_speed = 5.0

@export var dodge_distance: float = 50.0
@export var dodge_cooldown: float = 0.5  # seconds
var can_dodge = true
var invulnerable = false

# Timers
var dodge_timer = Timer.new()
var invulnerability_timer = Timer.new()


var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	add_child(dodge_timer)
	add_child(invulnerability_timer)
	dodge_timer.wait_time = dodge_cooldown
	invulnerability_timer.wait_time = 0.5  # Duration of invulnerability, adjust as needed
	dodge_timer.connect("timeout", Callable(self, "_on_dodge_timer_timeout"))
	invulnerability_timer.connect("timeout", Callable(self, "_on_invulnerability_timer_timeout"))
	

func _input(event) -> void:
	if event is InputEventMouseMotion:
		mouse_motion = event.relative
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var melee_area = $MeleeArea
	var enemy_count = melee_area.enemy_count
	#print("Enemies in melee range: ", enemy_count)
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	var forward_dir = -transform.basis.z.normalized()
	var right_dir = transform.basis.x.normalized()

	var input_x = Input.get_action_strength("movement_right") - Input.get_action_strength("movement_left")
	var input_z = Input.get_action_strength("movement_up") - Input.get_action_strength("movement_down")
	var movement_direction = (forward_dir * input_z + right_dir * input_x).normalized()

	if Input.is_action_pressed("movement_dodge") and can_dodge:
		perform_dodge(movement_direction)
	else:
		if movement_direction.length() > 0:
			velocity.x = movement_direction.x * player_speed
			velocity.z = movement_direction.z * player_speed
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 10.0)
	handle_rotation()
	mouse_motion = Vector2.ZERO
	move_and_slide()

func handle_rotation() -> void:
	var rotation_intensity = -mouse_motion.x * sensitivity
	if abs(rotation_intensity) > deadzone:
		rotate_y(rotation_intensity)
	else:
		# No rotation if the movement is within the deadzone
		return


func perform_dodge(movement_direction) -> void:
	var dodge_direction
	if movement_direction.length() > 0:
		dodge_direction = movement_direction.normalized() * player_speed * dodge_distance
	else:
		dodge_direction = transform.basis.z.normalized() * dodge_distance
		
	velocity += dodge_direction

	# Set invulnerability
	invulnerable = true
	invulnerability_timer.start()

	# Start cooldown timer and disable dodging
	can_dodge = false
	dodge_timer.start()

func _on_dodge_timer_timeout() -> void:
	can_dodge = true  # Allow dodging again

func _on_invulnerability_timer_timeout() -> void:
	invulnerable = false  # End invulnerability
