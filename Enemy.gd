extends CharacterBody3D

enum {
	Idle,
	Alerted,
	Ranged,
	Melee,
	Chasing,
	Repositioning
}

var state = Idle
var player
var staggered: bool = false
var dead = false

@onready var eyes = $Eyes
@onready var ranged_area = $RangedArea
@onready var melee_area = $MeleeArea
@onready var vision_area = $VisionArea
@onready var melee_timer: Timer = $MeleeTimer
@onready var ranged_timer: Timer = $RangedTimer
@onready var nav_agent = $NavigationAgent3D
@onready var raycast: RayCast3D = $RayCast3D

@export var turn_speed = 7.0
@export var walk_speed = 3.0
@export var health: int = 2
@export var pref_attack = "Ranged"
@export var maintain_distance = 10.0  # Distance the enemy tries to maintain from the player
@export var flanking_angle = 30.0  # Angle for flanking maneuvers
@export var random_variance = 2.0
@export var attack_angle_threshold_degrees = 10.0
@export var ranged_attack_interval = 4.0
@export var melee_attack_interval = 2.0
@export var flanking_chance = 0.1

var flanking_direction = Vector3.ZERO
var flanking_time = 0


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	melee_timer.connect("timeout", Callable(self, "_on_MeleeTimer_timeout"))
	ranged_timer.connect("timeout", Callable(self, "_on_RangedTimer_timeout"))

func _on_vision_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		state = Alerted

func _physics_process(delta: float) -> void:
	if health == 0:
		dead = true
	
	if !dead:
		#var global_direction_to_player = raycast.global_transform.origin - player.global_transform.origin
		#var local_direction_to_player = raycast.to_local(global_direction_to_player)
		#raycast.target_position = local_direction_to_player
		raycast.target_position.y = player.global_transform.origin.y - 1
		print("player: ", player.global_transform.origin, " Raycast target: ", raycast.target_position)
		raycast.force_raycast_update()
	
	if !staggered && !dead:
		match state:
			Idle:
				pass
			Alerted: 
				look_at_target(player.global_transform.origin)
				decide_next_action()
			Melee:
				melee_attack()
			Ranged:
				ranged_attack()
			Chasing:
				chase_player()
			Repositioning:
				move_to_range()

func _on_melee_timer_timeout() -> void:
	staggered = false

func _on_ranged_timer_timeout() -> void:
	staggered = false

func melee_attack() -> void:
	if is_engaged():
		look_at_target(player.global_transform.origin)
		if is_correctly_rotated():
			print("Attack!")
			staggered = true
			melee_timer.start(melee_attack_interval)
			return
	else:
		decide_next_action()
	pass
	
func ranged_attack() -> void:
	if !is_engaged() && is_in_range() && raycast.get_collider() == player:
		look_at_target(player.global_transform.origin)
		
		if is_correctly_rotated():
			print("Ranged attack!")
			staggered = true
			ranged_timer.start(ranged_attack_interval)
			return
	else:
		decide_next_action()
	pass

func look_at_target(target) -> void:
	var direction_to_target = (target - global_transform.origin).normalized()
	var current_forward = global_transform.basis.z.normalized()
	var desired_angle = current_forward.angle_to(direction_to_target)
	var rotation_step = turn_speed * get_process_delta_time()
	
	if abs(180 - rad_to_deg(desired_angle)) > 5:
		#rotate_y(sign(direction_to_target.cross(current_forward).y) * rotation_step)
		rotate_y(sign(direction_to_target.cross(current_forward).y) * min(rotation_step, abs(desired_angle)))

func is_correctly_rotated() -> bool:
	var direction_to_player = (player.global_transform.origin - global_transform.origin).normalized()
	var facing_direction = -global_transform.basis.z.normalized()
	var angle_to_player = facing_direction.angle_to(direction_to_player)
	if abs(rad_to_deg(angle_to_player)) < 5:
		return true
	else:
		return false
	

func decide_next_action() -> void:
	if pref_attack == "Melee":
		chase_player()
	else:
		move_to_range()
	pass
	
func is_engaged() -> bool:
	var bodies = melee_area.get_overlapping_bodies()
	if bodies.size() > 1:
		for body in bodies:
			if body == player:
				return true
	return false

func is_in_range() -> bool:
	var bodies = ranged_area.get_overlapping_bodies()
	if bodies.size() > 1:
		for body in bodies:
			if body.is_in_group("Player"):
				return true
	return false
	
func is_player_spotted() -> bool:
	var bodies = vision_area.get_overlapping_bodies()
	if bodies.size() > 1:
		for body in bodies:
			if body.is_in_group("Player"):
				return true
	return false

func chase_player() -> void:
	state = Chasing
	
	look_at_target(player.global_transform.origin)
	move_to_location(player.global_transform.origin)
	
func move_to_location(location) -> void:
	velocity = Vector3.ZERO
	var distance_to_target = global_transform.origin.distance_to(location)
	if distance_to_target > 1.0:
		nav_agent.set_target_position(location)
		var next_nav_point = nav_agent.get_next_path_position()
		if next_nav_point != Vector3.INF:
			look_at_target(player.global_transform.origin)
			velocity = (next_nav_point - global_transform.origin).normalized() * walk_speed
	else:
		velocity = Vector3.ZERO
	move_and_slide()
	
func move_to_range() -> void:
	if is_in_range() and raycast.get_collider() == player:
		if randf() < flanking_chance:
			print("Opting to flank despite clear shot.")
			state = Repositioning
			attempt_flanking()
		print("Player in range and visible, switching to Ranged state.")
		state = Ranged
	elif is_in_range() and raycast.get_collider() != player:
		print("Player not visible, attempting to flank.")
		state = Repositioning
		attempt_flanking()
	elif !is_in_range():
		var direction_to_player = (player.global_transform.origin - global_transform.origin).normalized()
		var random_adjustment = randf_range(-random_variance, random_variance)
		var effective_distance = maintain_distance + random_adjustment
		var target_position = player.global_transform.origin - direction_to_player * effective_distance
		move_to_location(target_position)	

func attempt_flanking():
	look_at_target(player.global_transform.origin)
	if flanking_time <= 0:
		flanking_direction = global_transform.basis.x.normalized()
		if randi() % 2 == 0:
			flanking_direction = -flanking_direction
		flanking_time = 2.0
		
	var flanking_distance = 7
	var flanking_position = global_transform.origin + flanking_direction * flanking_distance
	move_to_location(flanking_position)
	flanking_time -= get_process_delta_time()

func _on_melee_area_body_entered(body: Node3D) -> void:
	if body == player:
		print("Player in melee zone")
	if is_engaged():
		state = Melee



