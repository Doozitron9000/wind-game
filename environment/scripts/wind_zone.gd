# This windzone works by applying its wind vector to any "wind_affected" object
# that enters it and removing the wind influence on an object when it exits.
# All wind_affected objects MUST be given a wind var or this will not work.

# To use this scene add it to a level and set its children to be editable
# (Right click and enable editable children). THen resize the contained
# collision polygon as you see fit.
extends Area2D

# get both the visual and collision elements
@onready var visuals : Polygon2D = $MaskViewport/VisibleArea
# the collision polygon. THis is the source of truth when it comes to the
# shape of the wind area with everything else matching it
@onready var collision : CollisionPolygon2D = $Collision

# The vector representing the wind direction and magnitude
@export var wind : Vector2

func _ready() -> void:
	$Collision/DebugSprite.texture = $MaskViewport.get_texture()

## When a body enters this it has the wind applied to it
## if applicable
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("wind_affected"):
		body.wind = wind

## When a body exits  this it has the wind removed from it
## if applicable..... IF we end up having overlapping windzones
## this will be a problem and will need to be addressed
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("wind_affected"):
		body.wind = Vector2.ZERO
		
## gets the bounding box of the wind zone
func get_global_bounds() -> Rect2:
	# make default values extreme so the first point
	# will always overwrite them
	var min_x : float = INF
	var min_y : float = INF
	var max_x : float = -INF
	var max_y : float = -INF
	
	# now iterate through every point in the collision polygon
	# and figure out which is highest, lowest, leftmost, and rightmost,
	# so we can determine the bounding box
	for point in collision.polygon:
		var global_point = collision.to_global(point)
		min_x = min(min_x, global_point.x)
		max_x = max(max_x, global_point.x)
		min_y = min(min_y, global_point.y)
		max_y = max(max_y, global_point.y)
	
	# calculate the height and width of the bounding box
	var width : float = max_x-min_x
	var height : float = max_y-min_y
	
	# now create and return the bounding box
	return Rect2(Vector2(min_x, min_y), Vector2(width, height))

## Gets the shape of this wind zone
func get_local_shape() -> PackedVector2Array:
	return collision.polygon
	
## Gets the shape of this wind zone
func get_global_shape() -> PackedVector2Array:
	# make a repased version of the collision poly in global space
	var rebased_polygon : PackedVector2Array = PackedVector2Array()
	var global_bounds := get_global_bounds()
	# so iterate through every vector in our collision poly converting them
	# into global space before returning our new global polygon
	for point : Vector2 in collision.polygon:
		var global_point : Vector2 = collision.to_global(point)
		rebased_polygon.append(global_point - global_bounds.position)
		
	return rebased_polygon
