extends Node2D

const NOISE_HEIGHT := 32
const NOISE_WIDTH := 128

var density := 0.1

@onready var cloud_rect := $ColorRect

func _ready() -> void:
	cloud_rect.material.set_shader_parameter("cloud_meta", generate_noise())

func generate_noise() -> ImageTexture:
	# make the image and rng
	var img := Image.create(NOISE_WIDTH, NOISE_HEIGHT, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	for y in range(NOISE_HEIGHT):
		for x in range(NOISE_WIDTH):
			# r is a binary telling us if a cloud is there
			var r := 1.0 if rng.randf() < density else 0.0
			# g is which cloud so needs to be 1 of 4 discrete values
			var cloud_id := rng.randi_range(0, 3)
			# now the g value can be used to get the top of the texture
			var g := cloud_id * 0.25
			# b and a are unsused for now so can just be 1
			img.set_pixel(x, y, Color(r, g, 1.0, 1.0))
	 
	return ImageTexture.create_from_image(img)
