extends RigidBody2D

# the amount of wind applied to this. I figure a hook should be less affected
# by wind since it has a smaller sail area
const WIND_FRACTION : float = 0.2
# the length of a rope segment
const SEGMENT_LENGTH : float = 64

# A dictionary of winds currently affecting the player keyed to the source id
var winds : Dictionary = {}
# the total wind force currently applyinga to this object
var total_wind : Vector2 = Vector2.ZERO
# a var to track the normalised wind direction. using a var here spares us
# having to calculate this every frame
var wind_direction : Vector2
# the strength of the currently applied wind
var wind_strength : float = 0.0
# the array of segments
var segments : Array[RopeSegment] = []
# the entity that launched this
var launcher : Node2D
# the attachment point
var attachment : StaticBody2D
# the number of segmets int he hook
var segment_count : float = 8
# bool to track if this is currently launching
var launching := true
# bool to track if the whole rope has finished spawning
var spawned := false

# the pin joint to attach us to the attachment point
@onready var final_pin : PinJoint2D = $FinalPin
# the rope segment scene
@onready var segment_scene := preload("res://interactable/rope/rope_segment.tscn")
# the raycast detector
@onready var detector1 : RayCast2D = $Detector
@onready var detector2 : RayCast2D = $Detector2
@onready var detector3 : RayCast2D = $Detector3
# the line that draws the rope's initial appearance
@onready var initial_draw : Line2D = $InitialDraw
# the point where the rope connects to the hook
@onready var attach_point : Node2D = $AttachPoint

# on process apply the wind
func _physics_process(delta: float) -> void:
	apply_impulse(total_wind * delta)
	if launching:
		# get which ray if any is colliding
		var colliding : RayCast2D = get_colliding()
		if colliding:
			_on_hit(colliding.get_collider(), colliding.get_collision_point())
			if !spawned:
				spawn_remainder()
		if !spawned:
			if initial_draw:
				initial_draw.points[0] = to_local(get_physics_end())
				initial_draw.points[1] = to_local(launcher.get_grab_pos())
			if (launcher.get_grab_pos().distance_squared_to(get_physics_end()) >
				SEGMENT_LENGTH * SEGMENT_LENGTH && segments.size() < segment_count):
				add_segment()
				if segments.size() == segment_count:
					segments.back().interact(launcher)
					remove_line()
					spawned = true
			# the rope should also spawn if we have more or less stopped moving
			if linear_velocity.length_squared() < 0.1:
				spawn_remainder()

## when the detector enters a body creating anew static child of the hit object
## and pin self to it
func _on_hit(body: Node2D, collision_point: Vector2) -> void:	
	linear_velocity = Vector2.ZERO
	attachment = StaticBody2D.new()
	body.add_child(attachment)
	global_position = collision_point
	attachment.global_position = collision_point
	final_pin.node_a = attachment.get_path()
	launching = false

## get the global position of the last physics section of this rope
func get_physics_end() -> Vector2:
	if (segments.size() == 0):
		return attach_point.global_position
	return segments.back().get_end_pos()

## add a rope segment to this
func add_segment() -> void:
	var new_segment : RopeSegment = segment_scene.instantiate()
	new_segment.setup(SEGMENT_LENGTH)
	add_child(new_segment)
	new_segment.global_position = get_physics_end()
	new_segment.look_at(launcher.get_grab_pos())
	new_segment.rotation -= PI * 0.5
	if segments.size() == 0:
		new_segment.set_above_segment(self)
	else:
		var above_segment : RopeSegment = segments.back()
		above_segment.below_segment = new_segment
		new_segment.set_above_segment(above_segment)
	segments.append(new_segment)

## removes teh debug draw line
func remove_line() -> void:
	if initial_draw:
		initial_draw.queue_free()
		initial_draw = null

## spawns the remainder of the rope and attaches the player to it
func spawn_remainder() -> void:
	## add a segment and attach the player to it
	add_segment()
	segments.back().interact(launcher)
	# now add the remaining segments if any rotating them to create
	# the appearance of uncoiling
	var remaining_segments := segment_count - segments.size()
	remove_line()
	#for i in range(remaining_segments):
		#add_segment()
	spawned = true

## gets the colliding raycast if any
func get_colliding() -> RayCast2D:
	if detector1.is_colliding():
		return detector1
	elif detector2.is_colliding():
		return detector2
	elif detector3.is_colliding():
		return detector3
	return null
