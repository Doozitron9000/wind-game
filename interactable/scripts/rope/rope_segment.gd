class_name RopeSegment
extends RigidBody2D

# the amount of wind applied to this. I figure a rope should be less affected
# by wind since it has a smaller sail area
const WIND_FRACTION : float = 0.5
# the mass in kg of this segment at a length of 64
const MASS_64 : float = 1.0

# the segment prior to this one in the rope chain
@export var above_segment : PhysicsBody2D
@export var below_segment : PhysicsBody2D

# the length of the segment
var length : float = 64.0
# A dictionary of winds currently affecting the player keyed to the source id
var winds : Dictionary = {}
# the total wind force currently applying to this object
var total_wind : Vector2 = Vector2.ZERO
# a var to track the normalised wind direction. using a var here spares us
# having to calculate this every frame
var wind_direction : Vector2
# the strength of the currently applied wind
var wind_strength : float = 0.0
# the object currently climbing the rope segment
var climber : Node2D = null
# the position on the rope of the currently climbing object
var climber_pos : Vector2 = Vector2.ZERO

@onready var joint : PinJoint2D = $Joint
@onready var expanded_collision := $ExpandedCollision
@onready var regular_collision := $CollisionArea
@onready var detection_collision := $DetectionArea/DetectionCollsion
@onready var visuals := $ColorRect

func setup(new_length : float) -> void:
	length = new_length
	
func _ready() -> void:
	var mid_point = length/2
	# now set everything's size
	visuals.size.y = length
	detection_collision.shape.size.y = length
	expanded_collision.shape.size.y = length
	detection_collision.position.y = mid_point
	expanded_collision.position.y = mid_point
	# the regular collision is a capsule not a rect
	regular_collision.position.y = mid_point
	regular_collision.shape.height = length
	# set the mass based on length
	mass = length/64 * MASS_64
	# if the above segment is already set as wouild be the case if this seg
	# was spawned normally set it
	if above_segment:
		set_above_segment(above_segment)
	
func set_above_segment(new_above_segment : PhysicsBody2D) -> void:
	above_segment = new_above_segment
	joint.node_a = above_segment.get_path()

# on process apply the wind
func _physics_process(delta: float) -> void:
	# if this is being grappled a greater wind impulse should be applied to it
	# for now lets just add the climbers wind
	if climber:
		var wind_sum := total_wind * WIND_FRACTION
		if climber.is_in_group("wind_affected"):
			wind_sum += climber.total_wind
		apply_impulse(wind_sum * delta)
	else:
		apply_impulse(total_wind * delta * WIND_FRACTION)

## to run when something attempts to grab the rope.
## interactor is the object interacting with the rope.
func interact(interactor : Node2D) -> void:
	interactor.grab_rope(self)
	climber = interactor
	# now move the climber to the nearest point on the segment
	var start_pos : Vector2 = closest_point_on_segment(climber.get_grab_pos())
	move_climber(start_pos)
	# make doubly sure that climber pos has no x
	climber_pos = Vector2(0.0, to_local(start_pos).y)
	expand_collision()

## move a climber accounting for their grab point
func move_climber(new_position : Vector2) -> void:
	# get the offset between the grab point and interactor position
	var offset = climber.global_position - climber.get_grab_pos()
	climber.global_position = new_position + offset
	
func climb(vertical : float, horizontal : float) -> void:
	# first move the climber up or down the rope
	climber_pos.y += vertical
	# before applying the move up see if it would take us above the top of this
	# segment
	if climber_pos.y < 0:
		if above_segment is RopeSegment:
			above_segment.interact(climber)
			release()
		else:
			# otherwise just move to the top of the rope
			climber_pos = Vector2.ZERO
			move_climber(to_global(climber_pos))
		return
	move_climber(to_global(climber_pos))
	# if the climber has moved below this segment then move them to the one
	# below or lock to the bottom of the rope if there is no such segment
	if climber_pos.y > length:
		if below_segment:
			below_segment.interact(climber)
			release()
		else:
			climber_pos = Vector2(0, length)
			move_climber(to_global(climber_pos))
	# finally apply any swing impulse the player is applying.....
	# by simply applying this directly we get a force that reduces when facing
	# along the length of the segment that essen
	apply_central_impulse(Vector2(horizontal, 0))
# get the closest point on this segment to a given Vector2
func closest_point_on_segment(point: Vector2) -> Vector2:
	# first convert the point to local space
	point = to_local(point)
	# since this isn't rotated the y of the now localised target point
	# is all we care about when determining time along the length of this
	# segement
	# clamp the time between 0 and 1
	var time = clamp(point.y / length, 0.0, 1.0)
	# now return the point in global space. since we know the top is 0 in local
	# this is just our time x our bottom
	return to_global(Vector2(0.0, length * time))

func release() -> void:
	climber = null
	climber_pos = Vector2.ZERO
	shrink_collision()

## get the hypothetical velocity a climber should have given their point
func climber_velocity() -> Vector2:
	# get our local tangential velocity for the climber pos..... keep in mind
	# that +ve angular velocity is clockwise
	var local_tv = angular_velocity * (climber_pos.y - length/2) * -1
	# now we need to turn this into a velocity vector and transform it into
	# world space without translating to our actual position so as to just give
	# us a global velocity vector
	var global_tv = global_transform.basis_xform(Vector2(local_tv, 0))
	return linear_velocity + global_tv

func expand_collision() -> void:
	expanded_collision.disabled = false
	regular_collision.disabled = true
	# add a collision exception for the climber
	if climber:
		add_collision_exception_with(climber)
	# and set us to detect and mask layer 1
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

func shrink_collision() -> void:
	expanded_collision.disabled = true
	regular_collision.disabled = false
	# add a collision exception for the climber
	if climber:
		remove_collision_exception_with(climber)
	# and set us to detect and mask layer 1
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

## change the above node of this segment by deleting and recreating the joint
func change_nodea(new_a : PhysicsBody2D) -> void:
	joint.queue_free()
	joint = PinJoint2D.new()
	add_child(joint)
	joint.global_position = global_position
	joint.node_a = new_a.get_path()
	joint.node_b = self.get_path()
	above_segment = new_a

## gets the global position of the end of this segment
func get_end_pos() -> Vector2:
	return to_global((Vector2(0.0, length)))
