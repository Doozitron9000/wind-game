# This is effectively an interface to be inherited by all interactable objects
# that can be a Node2D (so don't need stuff specific to other types)

class_name Interactable
extends Node2D
 
func interact(interactor : Node2D) -> void:
	pass
