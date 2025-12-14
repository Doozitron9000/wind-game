extends CharacterBody2D

var speed := 500 # the player's max speed
var jump_velocity := -700 # the velocity imparted by the player jumping
var sprint_multiplier: float = 1.6
var spring_air_multiplier: float = 1.33
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var stamina := 100.0
var stamina_drained: bool = false

func _physics_process(delta: float) -> void:
	movement(delta)

## Handle the player's movement for this tick
## [param delta] is the time (in seconds) since this was last called
func movement(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if stamina >= 70:
		stamina_drained = false
	
	# Sprint check
	var current_speed := speed
	if Input.is_action_pressed("sprint") and stamina > 0 and stamina_drained == false:
		if is_on_floor() == true:
			current_speed *= sprint_multiplier
		elif is_on_floor() == false:
			current_speed *= spring_air_multiplier
		stamina -= 30 * delta
		print(stamina)
	else:
		stamina = min(stamina + 20 * delta, 100)
		stamina_drained = true
		print(stamina)
	
	# get the player's movement axisdaa
	# this returns a value between -1 and 1 where -1 is maximally leftward and
	# 1 is maximally rightward
	var input_dir = Input.get_axis("left", "right")
	#var direction = Input.get_vector("left", "right")
	
	velocity.x = input_dir * current_speed
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Move the character
	move_and_slide()
	
	
	
	
	#=============================================
	#===== locomotion goes here ==================
	#=============================================
