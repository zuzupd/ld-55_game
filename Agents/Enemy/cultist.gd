extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D

@export var health = 2
@export var speed = 5.0
@export var melee_threshold = 2.0
@export var melee_range = 2.0
@export var melee_preference = 0.5
@export var ranged_range = 10.0
@export var ranged_spell_preference = 0.25
@export var ranged_spell_range = 0.25
@export var aoe_range = 10.0
@export var aoe_preference = 0.25
@export var agro_range = 30

var provoked = false

@onready var firebolt_scene = $"./Firebolt"
#@export var explosion_scene

var player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	var melee_area = $"../Player/MeleeArea"
	if melee_area:
		melee_area.connect("enemy_count_changed", Callable(self, "_on_enemy_count_changed"))
	else:
		print("MeleeArea node not found.")

func update_target_location(target_location):
	nav_agent.target_position = target_location

func _on_enemy_count_changed(count):
	print("Updated enemy count: ", count)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if provoked:
		nav_agent.target_position = player.global_position
	
func _physics_process(delta: float) -> void:
	#var next_position = nav_agent.get_next_path_position()
	#var direction = global_position.direction_to(next_position)
	#var distance = global_position.distance_to(player.global_position)
	
	#if distance <= agro_range:
		#provoked = true
	#
	#if direction:
		#look_at_target(direction)
		#velocity.x = direction.x * speed
		#velocity.z = direction.z * speed
	#else:
		#velocity.x = move_toward(velocity.x, 0, speed)
		#velocity.z = move_toward(velocity.z, 0, speed)
	#
	#move_and_slide()
	
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	look_at_target(next_location)
	var new_velocity = (next_location - current_location).normalized() * speed
	
	nav_agent.set_velocity(new_velocity)
	

func isDead() -> bool:
	return false

func isDamaged() -> void:
	## stun for sec
	## play animation
	pass

func play_death() -> void:
	## Remove collision shape
	## Play animation
	## Delete instance afer timeout
	pass

func see_player() -> bool:
	## check if player is close
	## if yes go to fight mode
	return false

func decide_enemy_action(player, player_position, distance_to_player) -> void:
	if distance_to_player < melee_threshold:
		handle_melee_range(player)
	else:
		handle_long_range(player)
	pass

func handle_melee_range(player) -> void:
	var enemies = get_tree().get_nodes_in_group("Enemies")
	var nearby_enemies_count = 0
	for enemy in enemies:
		if enemy != self and enemy.global_transform.origin.distance_to(player.global_transform.origin) < melee_threshold:
			nearby_enemies_count += 1
	pass
	
func handle_long_range(player) -> void:
	pass
	
func magic_attack_direct() -> void:
	## check if not in melee range
	pass
# Enemy behavior:
# Idle when player is not nearby
# Alert when player is near
# If in melee range will perform melee attack
# If in bigger range, will flip a coin => 25 % will attack by spell, 75% will move into melee

func magic_attack_spacial() -> void:
	## check if not in melee range
	pass

func _on_vision_timer_timeout() -> void:
	var overlaps = $VisionArea.get_overlapping_bodies()
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap.is_in_group("Player"):
				var player = overlap
				var player_position = overlap.global_transform.origin
				var enemy_position = global_transform.origin
				var distance_to_player = enemy_position.distance_to(player_position)
				update_target_location(player.global_transform.origin)
				decide_enemy_action(player, player_position, distance_to_player)
				return
				
	


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, .25)
	move_and_slide()


func _on_navigation_agent_3d_waypoint_reached(details: Dictionary) -> void:
	#print("target reached")
	pass

func look_at_target(direction: Vector3) -> void:
	var adjusted_direction = direction
	adjusted_direction.y = 0
	look_at(global_position + adjusted_direction, Vector3.UP, true)
