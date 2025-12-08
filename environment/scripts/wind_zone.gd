# This windzone works by applying its wind vector to any "wind_affected" object
# that enters it and removing the wind influence on an object when it exits.
# All wind_affected objects MUST be given a wind var or this will not work.

# To use this scene add it to a level and set its children to be editable
# (Right click and enable editable children). THen resize the contained
# visuals as you see fit (the collsion will match these at run time).
extends Area2D

# get both the visual and collision elements
@onready var visuals : Polygon2D = $Visuals
@onready var collision : CollisionPolygon2D = $Collision

# The vector representing the wind direction and magnitude
@export var wind : Vector2

func _ready() -> void:
	# on ready match the collision polygon to the visual one
	collision.polygon = visuals.polygon

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
