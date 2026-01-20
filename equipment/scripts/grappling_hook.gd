extends Node2D

# state enum
enum State {
	IDLE,
	FIRING,
	ATTACHED,
	RETRACTING
}

# properties
var max_length : float = 500; # max cable length
# how many times a max lenght could be flown to in a second
var max_per_second : float = 6.0

# vars
var state : State = State.IDLE # current state of the gable
var flight_time : float = 0.0 # time the cable has been firing or retracting
var grapple_point : Vector2 = Vector2.ZERO

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
	pass

func get_grapple_force(delta : float, velocity: Vector2) -> Vector2:
	return Vector2.ZERO

func assess_hit() -> bool:
	# if we aren't colliding just return
	if !raycast.is_colliding():
		return false
	grapple_point = raycast.get_collision_point()
	state = State.ATTACHED
	return true
