extends AnimatedSprite2D

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
