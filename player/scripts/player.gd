extends CharacterBody2D

var speed := 200 # the player's max speed
var jump_velocity := -400 # the velocity imparted by the player jumping
var wind := Vector2.ZERO # The current wind acting on the player

func _physics_process(delta: float) -> void:
	movement(delta)

## Handle the player's movement for this tick
## [param delta] is the time (in seconds) since this was last called
func movement(delta: float) -> void:
	# get the player's movement axis
	# this returns a value between -1 and 1 where -1 is maximally leftward and
	# 1 is maximally rightward
	var input_dir = Input.get_axis("left", "right")
	
	#=============================================
	#===== locomotion goes here ==================
	#=============================================
