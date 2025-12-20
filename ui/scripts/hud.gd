extends CanvasLayer

# This hud can be attached to anything. just drag and drop a player into it
# via the editor and it should work
@export var player : Player # The player

@onready var stamina_bar = $MarginContainer/StaminaBar # The stamina bar

## every frame update the stamina bar
func _process(_delta: float) -> void:
	stamina_bar.value = player.stamina
