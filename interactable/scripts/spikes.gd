extends Interactable

# for now just respawn the player on interaction
func interact(interactor : Node2D) -> void:
	super(interactor)
	if interactor is Player:
		interactor.respawn()
