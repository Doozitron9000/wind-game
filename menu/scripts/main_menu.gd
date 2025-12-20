extends Control

## Temp play function redirects to MVP scene
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/test_level.tscn")

## quit the game
func _on_quit_button_pressed() -> void:
	get_tree().quit()
