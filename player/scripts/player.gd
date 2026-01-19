extends CharacterBody2D
class_name Player

# enum to track the player's state
enum PlayerState {
	DEFAULT,
	CLIMBING
}

# the amount of control the player has while in the air
const AIR_CONTROL : float = 0.5
# how rate at which the player can speed up and slow down while grounded
const ACCELERATION := 5000.0
# how fast to decelerate and change speed while in mid air when no wind is
# present
const BASE_AIR_DECEL : float = 400.0
# the player's max speed
const SPEED : float = 500.0
# the player's climb speed
const CLIMB_SPEED : float = 200.0
# the velocity imparted by the player jumping
const JUMP_VELOCITY : float = -700.0
# the amount velocity the always goes up when jumping of a rope
const ROPE_JUMP_Y : float = 0.5
# the max amount of force the player can apply to a rope by swinging themselves
const SWING_FORCE : float = 200
# the amount of swing force immediately applied if pushing off a wall
const SWING_WALL_FORCE : float = 200.0
# how much faster the player runs while sprinting
const SPRINT_MULTIPLIER: float = 1.5
# The max speed at which the player can slide down wall while gripping
const WALL_SLIDE : float = 200.0
# The stamina cost of sprinting per second
const SPRINT_COST : float = 30.0
# The stamina cost of gripping on a wall
const GRIP_COST : float = 15.0
# The fraction of wind applied when the player is grounded
const TRACTION : float = 0.5
# How much wind speed should be added to acceleration when pushing towards
# The player
const WIND_ACCEL : float = 1.0
# how high the played can jump straight up walls while sliding down them
const CLIMB_MOD : float = 0.5
const TERMINAL_VELOCITY : float = 2000
# how much time we ignore layer 4 when we try to drop down
const DROP_TIME : float = 0.2

# A dictionary of winds currently affecting the player keyed to the source id
var winds : Dictionary = {}
# the total wind force currently applying to this object
var total_wind : Vector2 = Vector2.ZERO
# a var to track the normalised wind direction. using a var here spares us
# having to calculate this every frame
var wind_direction : Vector2
# the strength of the currently applied wind
var wind_strength : float = 0.0

# how much time we have been dropping down for
var current_drop_time : float = 0	

# a temporary var representing teh amount of stamina required to wall jump
var wall_jump_stamina: float = 20.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var stamina := 100.0 # the player's current stamina
var stamina_drained: bool = false # whether the player's stamina is drained
var umbrella_open: bool = false # whether the umbrella is being used
# the percentage by which the umbrella reduces gravity and magnifies wind
var umbrella_strength: float = 0.5
var umbrella_terminal_velocity: float = 0.1

# the current object the player can interact with
var interaction_target : Node2D = null
# the player's current state
var state : PlayerState = PlayerState.DEFAULT
# the object the player is currently climbing
var climbed : Node2D = null

# vars to track grapple point and if grappling
var grapple_point : Vector2 = Vector2.ZERO
var grappling : bool = false
var grapple_length : float = 0.0
var grapple_stiffness : float = 2000.0
var grapple_damping : float = 120

# A Node2D where the player will respawn
@export var respawn_point : Node2D

# the class responsible for handling the player's animation
@onready var anim_graph := $AnimatedSprite2D

# the umbrella visual
@onready var umbrella := $FaceCursor/Umbrella

# the marker of the grab point (so shoulder height marker)
@onready var grab_point := $GrabPoint

## every physics tick update the player's movement and run their tools and
## interaction
func _physics_process(delta: float) -> void:
	# act based on the player's state
	match state:
		PlayerState.CLIMBING:
			climbing(delta)
		PlayerState.DEFAULT:
			interaction()
			movement(delta)
	tools()
	# Move the character
	move_and_slide()

## run the player's interaciton
func interaction() -> void:
	# if the player has something to interact with and jsut pressed intearct
	# run the interaction
	if interaction_target && Input.is_action_just_pressed("interact"):
		interaction_target.interact(self)
	
## handle the player's movement while climbing	
func climbing(delta: float) -> void:
	# if the player just hit interact again stop climbing
	if Input.is_action_just_pressed("interact"):
		release_rope()
		return
	# if the player just hit jump we should also release the 
	# rope but in this case we should also launch of it
	if Input.is_action_just_pressed("jump"):
		# release first so we get the ropes velocity
		release_rope()
		# and now add the jump velocity by first getting the direction
		# we pointing
		var jump_dir := Input.get_vector("left", "right", "up", "down")
		# jumping looks bad and feels bad if is just lateral so we should
		# always jump up by some amount (defined by the rope jump mod)
		# and then jump laterally by what is left
		# remember jump velocity is -ve by default
		var jump = jump_dir * JUMP_VELOCITY * (1-ROPE_JUMP_Y) * -1
		jump.y += (ROPE_JUMP_Y * JUMP_VELOCITY)
		velocity += jump
		return
	# get the player's up/down and left/right axis
	var vertical_dir : float = Input.get_axis("up", "down")
	var horizontal_dir : float = Input.get_axis("left", "right")
	
	var vertical_force := vertical_dir * CLIMB_SPEED * delta
	var horizontal_force := horizontal_dir * CLIMB_SPEED * delta
	# if we are against a wall we should amplify our swing if pushing off it
	if is_on_wall():
		var wall_normal : Vector2 = get_wall_normal()
		# check if we are pushing off the wall
		if wall_normal.dot(Vector2(horizontal_dir, 0.0)) > 0.0:
			horizontal_force += SWING_WALL_FORCE*horizontal_dir
	# rotate us to match the climbed object's rotation
	global_rotation = climbed.global_rotation
	climbed.climb(vertical_force, horizontal_force)
	
## Handle the player's movement for this tick
## [param delta] is the time (in seconds) since this was last called
func movement(delta: float) -> void:
	# make a var to track if we spent any stamin this tick. We will use it
	# later to determine if stamina should recharge and if we need to
	# check if the pc is now drained
	var stamina_spent : bool = false
	# Determine our current speed and sprint status
	var current_speed : float = SPEED
	# bool to track if we are sprinting
	var sprinting : bool = false
	if Input.is_action_pressed("sprint"):
		if stamina > 0 and stamina_drained == false:
			current_speed *= SPRINT_MULTIPLIER
			stamina -= SPRINT_COST * delta
			stamina_spent = true
			sprinting = true
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
	# we should use a var to track our effective wind
	var effective_wind = total_wind
	# if the umbrella is open we should check if it amplifies and redirects
	# the wind at all
	if umbrella_open:
		var umbrella_dir = Vector2.DOWN.rotated(umbrella.global_rotation)
		var alignment = umbrella_dir.dot(wind_direction)
		# if the umbrella and wind align the wind should be amplified
		if alignment > 0:
			# get how much extra wind we should have
			var extra_wind_strength = alignment * umbrella_strength * wind_strength
			# this extra wind should be redirected by the umbrella
			effective_wind += extra_wind_strength*umbrella_dir
	# if we are on the floor we can move as normal
	if is_on_floor():
		# if we are on the floor we add a reduced total wind to ourselves
		move_target += effective_wind * TRACTION
		# so our move target is just our speed * our input direction
		move_target.x += input_dir * current_speed
		# play the run animation or idle if not moving
		anim_graph.grounded(input_dir, sprinting)
	# if we aren't on the floor gravity should be applied
	else:
		# a value to represent the effective gravity the player is currently
		# under as well as effective terminal velocity
		var effective_gravity = gravity
		var effective_terminal_velocity = TERMINAL_VELOCITY
		# if the umbrella is open it should potentially affect the above
		# two values
		if umbrella_open:
			# get the gravity direction (just down for now
			var grav_dir: Vector2 = Vector2.DOWN
			# see how much our gravity lines up with our umbrella direction
			var umbrella_dir = Vector2.DOWN.rotated(umbrella.global_rotation)
			var alignment = umbrella_dir.dot(grav_dir)
			# if this is a negative number it means the gravity is facing
			# opposite the direction of gravity and so should slow our fall...
			# this should all only apply if we are moving down, otherwise
			# jump height etc will be magnified
			if alignment < 0 && velocity.y > 0:
				# lets see exactly how aligned we are..... our vectors should
				# already by normalised so our current alignment is already a
				# scalar reflecting how (un)aligned we are
				var grav_scalar : float = 1-abs(alignment)*umbrella_strength
				var tv_scalar : float = 1-abs(alignment)*umbrella_terminal_velocity
				effective_gravity *= grav_scalar
				effective_terminal_velocity *= tv_scalar
		# if we are in the air the full wind force should act on us
		move_target += effective_wind
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
				# play the wall slide animation
				anim_graph.wall_sliding()
		else:
			# added wind y to effective gravity multiplied by its accel
			# here wind is acting as a force not a target but i believe it should
			# feel right if we mult my accel since our wind force is essentially
			# magnitude*accel when used as a target i think.....?
			# we need to make sure wind doesn't apply if we are matching or
			# exceeding it but we can't clamp as that will neuter jumping
			var updraft = effective_wind.y*WIND_ACCEL * delta;
			# this here clamps upward wind forces such that they don't apply
			# if the player is already moving at them............ this may make
			# the umbrella less fun so may be worth disabling when it is active
			if velocity.y <= effective_wind.y and updraft < 0:
				updraft = 0.0
			velocity.y += effective_gravity * delta + updraft
			# clamp y velocity at terminal velocity
			# NOTE at the moment a downward wind still can't make you
			# fall faster than terminal velocity. I've not implmented
			# this as i think it is exceedingly unlikely to come up
			velocity.y = min(velocity.y, effective_terminal_velocity)
			
			anim_graph.airborne(velocity)
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
			# play the jump animation
			anim_graph.jump()
		# otherwise if they are pushing against a wall they can
		# wall jump but their velocity should push them away
		# from the wall. This should also require stamina
		elif is_on_wall():
			if !stamina_drained && stamina >= wall_jump_stamina:
				# if we are holding up we should jump straight up the wall
				if Input.is_action_pressed("up"):
					velocity.y = JUMP_VELOCITY * CLIMB_MOD

					# play the jump animation
					anim_graph.vert_wall_jump()

				# otherwise we should spring off the wall
				else:
					# so find the opposite direction of the wall we 
					# just touched
					var wall_normal : Vector2 = get_wall_normal()
					# we want to jump up a bit so find the vector half way between
					# up and the wall we just hit and jump that way
					var jump_direction : Vector2 = (up_direction + wall_normal).normalized()
					# now apply the jump velocity
					velocity += jump_direction * JUMP_VELOCITY * -1

					# play the jump animation
					anim_graph.wall_jump()

				stamina -= wall_jump_stamina
				stamina_spent = true

	#Dropdown through platforms
	if Input.is_action_pressed("down") and is_on_floor():
		set_collision_mask_value(4, false) # If we're press down we don't collide with layer 4 anymore
		current_drop_time = DROP_TIME # Sets the time we will not collide with layer 4
	
	if current_drop_time > 0: # Checks if we have a currently running drop timer
		current_drop_time -= delta # Counts down the drop timer
		if current_drop_time <= 0: # If our last operation was the one that took us below 0 we know that the time has expired
			set_collision_mask_value(4, true) # Once our drop time expires we turn collision with layer 4 back on
		
	# now check if stamina has been spent. If not recharge stamina. If so,
	# check if we should now enter the drained state
	if stamina_spent:
		if stamina <= 0:
			stamina_drained = true
	else:
		recover_stamina(delta)

	# if we are moving in the same direction as the wind we should also
	# have the wind spped added to our speed change
	if effective_wind.dot(move_target) > 0:
			speed_change += abs(effective_wind.x) * WIND_ACCEL

	# accelerate towards our move target then apply the character's movement
	velocity.x = velocity.move_toward(move_target, delta*speed_change).x
	
	# finally, apply the grapple force
	# Apply the grapple force
	velocity += get_grapple_force(delta)

## revovers an amount of stamina based on the current delta
func recover_stamina(delta: float) -> void:
	stamina = min(stamina + 20 * delta, 100)
	# if current stamina has exceeded 70% we should recover from being
	# drained
	if stamina >= 70:
		stamina_drained = false
		
# respawns the player at the current respawn point
func respawn() -> void:
	global_position = respawn_point.global_position
	velocity = Vector2.ZERO
	print("Player died!")

## affector to run when a body enters the player's detection zone
## everything on the layer that can trigger this (layer 3) MUST have a method
## called affect that takes a Node2D........ since godot has no interfaces
## this will have to suffice
func _on_detector_body_entered(body: Node2D) -> void:
	# if the body is something that can affect the player have it do so.
	# only affectors should be able to trigger this to begin with but this
	# check serves as a contignecy
	body.affect(self)

## manage the use of tools and equipment
func tools() -> void:
	# if the tool_1 button is pressed open the umbrella otherwise close it
	if Input.is_action_pressed("tool_1"):
		umbrella.visible = true
		umbrella_open = true
	else:
		umbrella.visible = false
		umbrella_open = false
	
	# if tool 2 is pressed use the grappling hook
	if Input.is_action_just_pressed("tool_2"):
		# pass the mpouse position
		grapple(get_global_mouse_position());

## function to run when a body exits the player's detection zone
## currently this function just returns the current interaction target
## to null
func _on_detector_body_exited(body: Node2D) -> void:
	if body == interaction_target:
		interaction_target = null

# funciton to run when the player grabs a rope
func grap_rope(to_climb : Node2D) -> void:
	state = PlayerState.CLIMBING
	climbed = to_climb
	# we should apply our velocity to rope segment as an impulse then set it
	# to zero so we don't go flying randomly on release'
	climbed.apply_impulse(velocity)
	velocity = Vector2.ZERO
	
# funciton to run when the player releases a rope
func release_rope() -> void:
	state = PlayerState.DEFAULT
	# get the velocity we should have from the rope segment
	var release_velocity : Vector2 = climbed.climber_velocity()
	climbed.release()
	climbed = null
	# now apply the release velocity
	velocity = release_velocity
	# reset global rotation
	global_rotation = 0.0

## gets the current global position of the grab point
func get_grab_pos() -> Vector2:
	return grab_point.global_position

## func to run when grapple is clicked
func grapple(point: Vector2) -> void:
	# if grappling stop doing so and return
	if grappling:
		grappling = false
		return
	# otherwise grapple the new point
	grapple_point = point
	grappling = true
	grapple_length = grapple_point.distance_to(grab_point.global_position)

## Apply our grappling hooks appropriate force
func get_grapple_force(delta: float) -> Vector2:
	# just return if we are within the grapple's length or not grappling
	if !grappling:
		return Vector2.ZERO
	# apply a force corresponding to our separation
	var difference : Vector2 = grapple_point - grab_point.global_position
	var dist_sq := difference.length_squared()

	if dist_sq <= grapple_length * grapple_length:
		return Vector2.ZERO
	var dist := sqrt(dist_sq) # ONE sqrt
	var stretch := dist - grapple_length
	var direction := difference / dist
	
	# calculate radial damping
	var damping : Vector2 = Vector2.ZERO
	var radial_vel := velocity.dot(direction)
	if radial_vel > 0:
		damping = direction * radial_vel * grapple_damping

	return (direction * stretch * grapple_stiffness - damping) * delta
