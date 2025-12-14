extends Area2D

@export var respawn_point: Node2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.global_position = respawn_point.global_position
		body.velocity = Vector2.ZERO  # stop leftover motion
		print("Player died!")
