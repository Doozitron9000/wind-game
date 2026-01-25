extends Node2D

# state enum
enum State {
	IDLE,
	FIRING,
	ATTACHED,
	RETRACTING
}

const REDIRECT : float = 0.1 # how much velocity is redirected by this tether

# properties
var max_length : float = 500; # max cable length
# how many times a max lenght could be flown to in a second
var max_per_second : float = 6.0
var stiffness : float = 400.0 # how much give the cable has
var damping : float = 5.0 # how much force is reduced when using the grapple

# vars
var state : State = State.IDLE # current state of the gable
var flight_time : float = 0.0 # time the cable has been firing or retracting
var grapple_point : Vector2 = Vector2.ZERO
var length : float = 0.0 # the length of the grapple cable

# onready vars
@onready var raycast := $RayCast
@onready var cable := $Cable
@onready var head := $Head

## draw on process
func _process(_delta: float) -> void:
	if state == State.IDLE: return
	cable.set_point_position(1, raycast.target_position)
	head.global_position = to_global(raycast.target_position)

## logic on physics process
func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			# just return if idle
			return
		State.FIRING:
			flight_time += delta
			var current_length : float = min(max_length, 
				max_length*flight_time*max_per_second)
			raycast.target_position = Vector2(current_length, 0.0)
			if assess_hit():
				return
			if current_length == max_length:
				state = State.RETRACTING
				flight_time = 0.0
		State.ATTACHED:
			raycast.target_position = to_local(grapple_point)
			return
		State.RETRACTING:
			flight_time += delta
			var current_length : float = max(0.0,
				max_length - max_length*flight_time*max_per_second)
			raycast.target_position = Vector2(current_length, 0.0)
			if current_length == 0.0:
				reset();

## reset the hook in its idle position
func reset() -> void:
	state = State.IDLE
	cable.visible = false
	head.visible = false
	flight_time = 0.0

## launch the grappling hook
func launch() -> void:
	match state:
		State.IDLE:
			state = State.FIRING
			cable.visible = true
			head.visible = true
		State.ATTACHED:
			state = State.RETRACTING
			release()

## release the grappling hook
func release() -> void:
	state = State.RETRACTING

## recalculates velocity to prevent the violation of this tether
func tether_velocity(velocity: Vector2, delta: float) -> Vector2:
	# if we aren't attached just return velocity
	if state != State.ATTACHED: return velocity
	# if we are within the cable return a velocity
	if length * length >= grapple_point.distance_squared_to(global_position):
		return velocity
	# vector from player to anchor
	var to_point := grapple_point - global_position
	var sep := to_point.length()

	# radial unit direction
	var dir := to_point / sep

	# --- split velocity ---
	var radial_speed := velocity.dot(dir)
	var radial_component := dir * radial_speed
	var tangential_component := velocity - radial_component

	# --- rotate radial into tangential ---
	# perpendicular to dir
	var tangent := Vector2(-dir.y, dir.x)

	# choose tangent direction that matches current tangential motion
	if tangential_component.dot(tangent) < 0.0:
		tangent *= -1.0

	var redirected : Vector2 = tangent * abs(radial_speed)
	
	# bottom-of-swing assist
	# basically because of the nature of this you get kinda stuck at the bottom
	# of the swing so this cheats and forces you to a vertical hang
	var verticalness : float = abs(dir.dot(Vector2.UP))   # 1 = vertical rope
	var tangential_speed_sq := tangential_component.length_squared()
	if verticalness > 0.95 and tangential_speed_sq < 400.0:
		var downward = signf(tangent.dot(Vector2.DOWN))
		if verticalness > 0.999:
			tangential_component = Vector2.ZERO
		else:
			if downward > 0:
				tangential_component = tangent * 40.0
			else:
				tangential_component = tangent * -40.0
	
	# --- recombine ---
	# but reduce redirected velocity the more it poitns up to prevent
	# infinite energy exploits
	var new_velocity : Vector2 = (tangential_component + 
		redirected * REDIRECT * (1-abs(Vector2.UP.dot(tangent))))
	
	# --- calculate bounce back ---
	var over := sep - length
	# spring force
	var accel := dir * stiffness * over
	# radial damping
	var radial_vel := velocity.dot(dir)
	var damped := dir * radial_vel * damping
	accel -= damped
	
	return new_velocity + accel * delta

func assess_hit() -> bool:
	# if we aren't colliding just return
	if !raycast.is_colliding():
		return false
	grapple_point = raycast.get_collision_point()
	state = State.ATTACHED
	length =  grapple_point.distance_to(global_position)
	return true

## Ignore the given object from ray cast checks
func ignore(to_ignore: Node2D) -> void:
	raycast.add_exception(to_ignore)
