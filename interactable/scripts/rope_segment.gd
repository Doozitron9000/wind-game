class_name RopeSegment
extends RigidBody2D

# the amount of wind applied to this. I figure a rope should be less affected
# by wind since it has a smaller sail area
const WIND_FRACTION : float = 0.5

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

# on ready assign node b to the pin joint
func _ready() -> void:
	joint.node_a = above_segment.get_path()

# on process apply the wind
func _physics_process(delta: float) -> void:
	# if this is being grappled a greater wind impulse should be applied to it
	# for now lets just make this the full impulse but we may want to change it
	# later
	if climber:
		apply_impulse(total_wind * delta * (WIND_FRACTION+1))
	else:
		apply_impulse(total_wind * delta * WIND_FRACTION)

# to run when the body is called to affect something
func affect(body : Node2D) -> void:
	body.interaction_target = self

# to run when something attempts to grab the rope
func interact(interactor : Node2D) -> void:
	interactor.grap_rope(self)
	climber = interactor
	# now move the interactor to the nearest point on the segment
	interactor.global_position = closest_point_on_segment(interactor.global_position)

func climb(vertical : float, horizontal : float) -> void:
	# first move the climber up or down the rope
	climber_pos.y += vertical
	# before applying the move up see if it would take us above the top of this
	# segment
	if climber_pos.y < 0:
		if above_segment is RopeSegment:
			climber.global_position = to_global(climber_pos)
			above_segment.interact(climber)
			release()
		else:
			# otherwise just move tot he top of the rope
			climber_pos = Vector2.ZERO
			climber.global_position = to_global(climber_pos)
		return
	climber.global_position = to_global(climber_pos)
	# if the climber has moved below this segment then move them to the one
	# below or release the rope if there is no such segment
	if climber_pos.y > length:
		if below_segment:
			below_segment.interact(climber)
			release()
		else:
			climber.release_rope()

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
	climber_pos = Vector2(0.0, length * time)
	return to_global(climber_pos)

func release() -> void:
	climber = null
	climber_pos = Vector2.ZERO
