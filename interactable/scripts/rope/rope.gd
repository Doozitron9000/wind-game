@tool
extends Node2D

@export var segment_length : float = 64.0:
	set(v):
		segment_length = max(16, v)
		queue_redraw()
		
@export var segment_count : int = 5:
	set(v):
		segment_count = max(1, v)
		queue_redraw()

# the array of segments
var segments : Array[RopeSegment] = []

@onready var segment_scene := preload("res://interactable/rope/rope_segment.tscn")
@onready var top := $Top

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# make and parent all the segments
	for i in range(segment_count):
		var new_segment : RopeSegment = segment_scene.instantiate()
		new_segment.setup(segment_length)
		add_child(new_segment)
		new_segment.position.y = i * segment_length
		segments.append(new_segment)
		
	# now await the first physics frame before adding the segments so we know
	# everything is prepper and read
	await get_tree().physics_frame
	var first_segment := segments[0]
	first_segment.position = Vector2.ZERO
	first_segment.set_above_segment(top)
	for i in range(segment_count - 1):
		var previous_segment := segments[i]
		var current_segment := segments[i+1]
		current_segment.set_above_segment(previous_segment)
		previous_segment.below_segment = current_segment

# draw function for drwaing editor hints
func _draw():
	if not Engine.is_editor_hint():
		return

	var y := 0.0
	var col := Color(0.3, 0.9, 1.0)

	for i in range(segment_count):
		var start := Vector2(0, y)
		var end := Vector2(0, y + segment_length)

		# segment line
		draw_line(start, end, col, 3.0)

		# joint dot
		draw_circle(end, 4.0, Color.WHITE)

		y += segment_length
