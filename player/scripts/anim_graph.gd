extends AnimatedSprite2D
# bool to track if we are currently in a transition animation
var transition := false
# bool to track if the player is currently on all fours
var all_fours := false

## play grounded animations
func grounded(input_dir : float, sprinting : bool) -> void:
	# check if the player should standup or sit down
	if all_fours != sprinting:
		# if we needa change stance do so and return
		change_stance(input_dir)
		return
	# if we are mid transition just return
	if transition: return
	if (input_dir == 0.0):
		# if on all fours play the all fours idle
		if all_fours:
			play("Quad_Idle")
		else:
			play("Idle")
	else:
		if sprinting:
			play("Sprint")
		else:
			play("Run")
		# flip the sprite if going right
		if (input_dir > 0):
			flip_h = true
		else:
			flip_h = false

## play airborne animations.
func airborne(character_velocity : Vector2) -> void:
	# if we are mid transition just return
	if transition: return
	# otherwise play the fall animation
	play("Fall")
	var move_x : float = character_velocity.x
	# rotate to face move direction
	if (move_x != 0):
		if (move_x > 0):
			flip_h = true
		else:
			flip_h = false

## Play wall slide animation
func wall_sliding() -> void:
	# if we are mid transition just return
	if transition: return
	play("Wall_Slide")

## Play the jump animation
func jump() -> void:
	play("Jump")
	transition = true

## play the wall jump animation
func wall_jump() -> void:
	play("Wall_Jump")
	transition = true
	
## play the vert wall jump animation
func vert_wall_jump() -> void:
	play("Wall_Jump_Vert")
	transition = true

## to run when an animation finishes.
func _on_animation_finished() -> void:
	# we have always finished our jump animation if this is hit
	transition = false

## play the change stance animation
func change_stance(input_dir : float) -> void:
	if all_fours:
		play_backwards("Drop")
		all_fours = false
	else:
		play("Drop")
		all_fours = true
	# we are now transitioning
	transition = true
	# don't worry about flipping if not going in a direction
	if input_dir == 0:
		return
	# flip the sprite if going right
	if (input_dir > 0):
		flip_h = true
	else:
		flip_h = false
