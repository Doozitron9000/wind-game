extends Node

@export var player : CharacterBody2D
@export var camera : Camera2D

## every frame move the camera to the player
func _process(_delta: float) -> void:
	camera.global_position = player.global_position
