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
const SPRINT_MULTIPLIER: float = 1.0
# The max speed at which the player can slide down wall while gripping
const WALL_SLIDE : float = 200.0
# The stamina cost of sprinting per second
const SPRINT_COST : float = 30.0
# The stamina cost of gripping on a wall
const GRIP_COST : float = 15.0
# The fraction of wind applied when the player is grounded
const TRACTION : float = 0.5

# A dictionary of winds currently affecting the player keyed to the source id
var winds : Dictionary = {}
# the total wind force currently applying to this object
var total_wind : Vector2 = Vector2.ZERO

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
	# make a var to track if we spent any stamin this tick. We will use it
	# later to determine if stamina should recharge and if we need to
	# check if the pc is now drained
	var stamina_spent : bool = false
	# Determine our current speed and sprint status
	var current_speed : float = SPEED
	if Input.is_action_pressed("sprint"):
		if stamina > 0 and stamina_drained == false:
			current_speed *= SPRINT_MULTIPLIER
			stamina -= SPRINT_COST * delta
			stamina_spent = true
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
		# if we are on the floor we add a reduced total wind to ourselves
		move_target += total_wind * TRACTION
		# so our move target is just our speed * our input direction
		move_target.x += input_dir * current_speed
	# if we aren't on the floor gravity should be applied
	else:
		# if we are in the air the full wind force should act on us
		move_target += total_wind
		# next apply gravity accounting for wall slide
		# if we are pushing against a wall we should slide not fall.
		# this should only apply if we are moving down tho otherwise
		# jumping against walls results in sliding up
		#  for now i have also set this to consume stamina
		if (is_on_wall() && get_wall_normal().x == input_dir * -1 &&
				velocity.y >= WALL_SLIDE && stamina > 0 && !stamina_drained):
				velocity.y = WALL_SLIDE
				stamina -= GRIP_COST * delta
				stamina_spent = true
		else:
			velocity.y += gravity * delta
		# and our move target should be reduced to our air control
		move_target.x += input_dir * current_speed * AIR_CONTROL
		# our speed change in mid air should default to its base line
		# which represents both player control and wind resistance
		speed_change = BASE_AIR_DECEL
		# to give the player more control in the air this should be reduced
		# when the player is pulling in the same direction as their movement
		if input_dir == sign(velocity.x):
			speed_change = BASE_AIR_DECEL*(1-AIR_CONTROL)
		
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
				stamina_spent = true
			
	
	# now check if stamina has been spent. If not recharge stamina. If so,
	# check if we should now enter the drained state
	if stamina_spent:
		if stamina <= 0:
			stamina_drained = true
	else:
		recover_stamina(delta)
	#print the stamina debug output
	print(stamina)
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
