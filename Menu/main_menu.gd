extends Control


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_new_fps_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/fps_level.tscn")


func _on_new_isometric_button_pressed() -> void:
	pass # Replace with function body.


func _on_new_3_rd_person_button_pressed() -> void:
	pass # Replace with function body.


func _on_options_button_pressed() -> void:
	pass # Replace with function body.
