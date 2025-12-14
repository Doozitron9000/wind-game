extends CharacterBody2D

# the amount of control the player has while in the air
const AIR_CONTROL : float = 0.5
# how rate at which the player can speed up and slow down while grounded
const ACCELERATION := 5000.0
# how fast to decelerate and change speed while in mid air when no wind is
# present
const BASE_AIR_DECEL : float = 400.0
# the player's max speed
const SPEED : float = 500.0
# the velocity imparted by the player jumping
const JUMP_VELOCITY : float = -700.0
# how much faster the player runs while sprinting
const SPRINT_MULTIPLIER: float = 1.

# a temporary var representing teh amount of stamina required to wall jump
var wall_jump_stamina: float = 20.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var stamina := 100.0 # the player's current stamina
var stamina_drained: bool = false # whether the player's stamina is drained

# every physics tick update the player's movement
func _physics_process(delta: float) -> void:
	movement(delta)

## Handle the player's movement for this tick
## [param delta] is the time (in seconds) since this was last called
func movement(delta: float) -> void:
	# Determine our current speed and sprint status
	var current_speed : float = SPEED
	if Input.is_action_pressed("sprint"):
		if stamina > 0 and stamina_drained == false:
			current_speed *= SPRINT_MULTIPLIER
			stamina -= 30 * delta
			print(stamina)
		else:
			stamina_drained = true
			recover_stamina(delta)
	# if we aren't sprinting we should always recover stamina if possible
	else:
		recover_stamina(delta)
	# get the player's movement axis
	# this returns a value between -1 and 1 where -1 is maximally leftward and
	# 1 is maximally rightward
	var input_dir = Input.get_axis("left", "right")
	# we need a variable to track the player's current move target
	# (i.e. that move vector they will accelerate towards)'
	var move_target : Vector2 = Vector2.ZERO
	# we should also make a var to track how quickly we should 
	# change speed this tick and default it to the standard acceleration
	var speed_change : float = ACCELERATION
	# if we are on the floor we can move as normal
	if is_on_floor():
		# so our move target is just our speed * our input direction
		move_target.x = input_dir * current_speed
	# if we aren't on the floor gravity should be applied
	else:
		# first apply gravity
		velocity.y += gravity * delta
		# and our move target should be reduced to our air control
		move_target.x = input_dir * current_speed * AIR_CONTROL
		# our speed change in mid air should default to its base line
		# which represents both player control and wind resistance
		speed_change = BASE_AIR_DECEL
		# to give the player more control in the air this should be reduced
		# when the player is pulling in the same direction as their movement
		if input_dir == sign(velocity.x):
			speed_change = BASE_AIR_DECEL*1-AIR_CONTROL
		
	# Jump
	if Input.is_action_just_pressed("jump"):
		# if the player is ont he floor they can always jump
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		# otherwise if they are pushing against a wall they can
		# wall jump but their velocity should push them away
		# from the wall. This should also require stamina
		elif is_on_wall():
			if !stamina_drained && stamina >= wall_jump_stamina:
				# so find the opposite direction of the wall we 
				# just touched
				var wall_normal : Vector2 = get_wall_normal()
				# we want to jump up a bit so find the vector half way between
				# up and the wall we just hit and jump that way
				var jump_direction : Vector2 = (up_direction + wall_normal).normalized()
				# now apply the jump velocity
				velocity += jump_direction * JUMP_VELOCITY * -1
				stamina -= wall_jump_stamina
				if stamina == 0:
					stamina_drained = true
			
	
	# accelerate towards our move target then apply the character's movement
	velocity.x = velocity.move_toward(move_target, delta*speed_change).x
	# Move the character
	move_and_slide()

## revovers an amount of stamina based on the current delta
func recover_stamina(delta: float) -> void:
	stamina = min(stamina + 20 * delta, 100)
	# if current stamina has exceeded 70% we should recover from being
	# drained
	if stamina >= 70:
		stamina_drained = false
	print(stamina)
