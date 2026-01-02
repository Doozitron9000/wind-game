class_name Cloud
extends Sprite2D

# this clouds relative position............ these are not conventional coords
# but rather go from 0 - 1 where 1 is far right
var z : float = 0.0
# the xy origin of this cloud in global space
var origin : Vector2 = Vector2.ZERO
# the dimensions of the cloud
var dimensions : Vector2 = Vector2.ZERO
