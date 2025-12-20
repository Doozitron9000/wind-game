extends CanvasLayer

# This hud can be attached to anything. just drag and drop a player into it
# via the editor and it should work
@export var player : Player # The player

# whether the game is paused or not
var paused : bool = false

@onready var stamina_bar = $BottomLeftContainer/StaminaBar # The stamina bar
@onready var pause_menu = $PauseMenu # The pause menu box

## every frame update the stamina bar
func _process(_delta: float) -> void:
	stamina_bar.value = player.stamina

## function to run when the pause button is pressed
func _on_pause_button_pressed() -> void:
	if paused:
		unpause()
	else:
		pause()

## function to run when the resume button is pressed
func _on_resume_button_pressed() -> void:
	unpause()

## pause the game
func pause() -> void:
	paused = true
	pause_menu.visible = true
	get_tree().paused = true

## unpause the game
func unpause() -> void:
	paused = false
	pause_menu.visible = false
	get_tree().paused = false

## return to the main menu
func _on_main_menu_button_pressed() -> void:
	# unpause the game so it isn't paused if play is returned to
	unpause()
	# return to the main menu
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")
