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
	# We need this to match shape of the windzone
	var padded_shape : PackedVector2Array = zone.get_padded_shape()
	
	visible_area.polygon = padded_shape
