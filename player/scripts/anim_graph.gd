extends AnimatedSprite2D
# bool to track if we are currently in a jump animaton
var jumping := false

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
	# if we are mid jump just return
	if jumping: return
	# otherwise play the fall animation
	play("Fall")
	var move_x : float = character_velocity.x
	# rotate to face move direction
	if (move_x != 0):
		if (move_x > 0):
			flip_h = true
		else:
			flip_h = false

## trigger a jump
func jump() -> void:
	play("Jump")
	jumping = true

## to run when an animation finishes.
func _on_animation_finished() -> void:
	# we have always finished our jump animation if this is hit
	jumping = false
