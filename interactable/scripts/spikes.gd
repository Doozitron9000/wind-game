extends Area2D

# for now just respawn the player on interaction
func affect(to_affect : Node2D) -> void:
	if to_affect is Player:
		to_affect.respawn()
