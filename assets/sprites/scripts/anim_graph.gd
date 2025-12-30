extends AnimatedSprite2D

@export var character : CharacterBody2D

var jump : bool = false
var wall_jump : bool = false
var climb_jump : bool = false
var sprint : bool = false
var run : bool = false


func _process(delta: float) -> void:
	var falling : bool = !character.is_on_floor()
