extends Area2D

@onready var segment_main := $".."

## to run when the body is called to affect something
func affect(body : Node2D) -> void:
	body.interaction_target = segment_main
