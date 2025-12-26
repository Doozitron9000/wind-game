extends AnimatedSprite2D

## play grounded animations
func grounded(input_dir : float) -> void:
	if (input_dir == 0.0):
		play("Idle")
	else:
		play("Run")
		# flip the sprite if going right
		if (input_dir > 0):
			flip_h = true
		else:
			flip_h = false

## play airborne animations.
func airborne(character_velocity : Vector2) -> void:
	play("Fall")
	var move_x : float = character_velocity.x
	# rotate to face move direction
	if (move_x != 0):
		if (move_x > 0):
			flip_h = true
		else:
			flip_h = false
