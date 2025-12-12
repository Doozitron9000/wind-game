extends SubViewport

# the parent object of the whole zone
@onready var zone : Area2D = $".."
# the visible area within this viewport
@onready var visible_area : Polygon2D = $VisibleArea

## on ready make a deferred call to resize this to match the zone's
## bounding box
func _ready() -> void:
	# initialize the bounding box 
	call_deferred("initialize")

## function to initialize this zone (currently just sets size)
func initialize() -> void:
	# We need this to match the size of the wind zone
	var global_bounds : Rect2 = zone.get_global_bounds()
	size = global_bounds.size
	var global_shape : PackedVector2Array = zone.get_global_shape()
	
	visible_area.polygon = global_shape
