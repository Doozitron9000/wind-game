extends AnimatedSprite2D
# bool to track if we are currently in a transition animation
var transition := false

## play grounded animations
func grounded(input_dir : float) -> void:
	# if we are mid transition just return
	if transition: return
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
