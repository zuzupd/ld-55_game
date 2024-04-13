extends Node3D

@export var camera_angle = 10.0
var camera_rotation = -50.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var spring_length = $SpringArm3D.get_hit_length()
	$SpringArm3D/Camera3D.rotation_degrees.x = camera_rotation + camera_angle * spring_length

func _on_spring_arm_3d_visibility_changed() -> void:
	var spring = $SpringArm3D.get_hit_length()
	print(spring)
