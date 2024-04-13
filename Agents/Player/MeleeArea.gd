extends Area3D


func _ready():
	# Connect signal for entering and exiting the area
	connect("body_entered", Callable(self, "_on_Body_entered"))
	connect("body_exited", Callable(self, "_on_Body_exited"))

	# Set up the collision layer and mask if not done in the editor
	# collision_layer = 1
	# collision_mask = 1

var enemy_count = 0

func _on_Body_entered(body):
	if body.is_in_group("Enemies"):
		enemy_count += 1
		update_enemy_count()

func _on_Body_exited(body):
	if body.is_in_group("Enemies"):
		enemy_count -= 1
		update_enemy_count()

func update_enemy_count():
	emit_signal("enemy_count_changed", enemy_count)
	
signal enemy_count_changed(count)
