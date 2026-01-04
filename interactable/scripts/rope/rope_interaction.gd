extends Area2D

@onready var segment_main := $".."

## to run when the body is called to affect something
func affect(body : Node2D) -> void:
	body.interaction_target = self

## to run when something attempts to grab the rope.
## interactor is the object interacting with the rope.
func interact(interactor : Node2D) -> void:
	segment_main.interact(interactor)
