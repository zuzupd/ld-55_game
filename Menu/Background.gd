extends TextureRect

func _ready():
	# Assuming your TextureRect is named "Background"
	var background: TextureRect = $"."
	background.texture = preload("res://Assets/Background1.png")
	background.stretch_mode = STRETCH_KEEP_ASPECT_COVERED
