extends Node2D

# Array of cloud UV rectangle coordinates in the cloud texture atlas
const CLOUD_UVS: Array = [
	Rect2(0.0, 0.00, 0.5, 0.25),
	Rect2(0.0, 0.25, 0.5, 0.25),
	Rect2(0.0, 0.50, 0.5, 0.25),
	Rect2(0.0, 0.75, 0.5, 0.25),
	Rect2(0.5, 0.0, 0.5, 0.5),
	Rect2(0.5, 0.5, 0.5, 0.5),
]
# the camera to use for parallax calculations
@export var camera: Camera2D
# the number of clouds
@export var cloud_count: int = 50
# the size of the world
@export var world_size: Vector2 = Vector2(4096, 2048)
# The minimum and maximum depth of the clouds (1 is near/front, 0 is far/back)
@export var depth_min: float = 0.05
@export var depth_max: float = 0.99
# The velocity of the wind affecting the clouds
@export var wind_velocity: Vector2 = Vector2(20.0, 0.0)
@export var cloud_base_y: float = 0.0 # where near clouds cluster
@export var horizon_y: float = -500.0 # where far clouds converge to
@export var y_spread: float = 50.0 # random scatter around base
# Accumulator for the wind offset, to create continuous movement
var _wind_accumulator: Vector2 = Vector2.ZERO
# The shader material used for the clouds, stored for updating shader parameters
var _mat: ShaderMaterial
# Reference to the MultiMeshInstance2D node for setting up cloud instances
@onready var mmi: MultiMeshInstance2D = $Clouds
@onready var sky_background: ColorRect = $Background/SkyRect

func _ready():
	# Set the background's horizon var
	sky_background.material.set_shader_parameter("horizon", world_y_to_screen_uv(horizon_y))
	# Set up the shader material for the clouds
	var mat = ShaderMaterial.new()
	mat.shader = load("res://environment/shaders/cloud_parallax.gdshader")
	mmi.material = mat
	_mat = mat
	_mat.set_shader_parameter("cloud_map", load("res://environment/images/Clouds.png"))
	# Set up the MultiMesh for the clouds
	mmi.multimesh.use_custom_data = true
	mmi.multimesh.instance_count = cloud_count
		
	# Initialize each cloud instance with random depth and position, and store depth in custom data
	# depth: 1 = near (large, fast), 0 = far (small, slow)
	var clouds = []
	for i in cloud_count:
		# disproportionately spawn distant clouds
		var depth = lerp(depth_min, depth_max, 1.0 - pow(randf(), 0.1))  # bias towards lower depth (farther clouds)
		# Far clouds (low depth) near horizon, near clouds (high depth) spread more
		var y = lerp(horizon_y, cloud_base_y, depth) + randf_range(-y_spread, y_spread)
		var viewport_width = get_viewport_rect().size.x
		var x_range = lerp(viewport_width * 0.5, world_size.x * 0.5, depth)
		var base_pos = Vector2(
			camera.global_position.x + randf_range(-x_range, x_range),
			y
		)
		clouds.append({"depth": depth, "base_pos": base_pos})

	clouds.sort_custom(func(a, b): return a.depth < b.depth)  # far first for correct layering

	# now the clouds are sorted back to front, we can assign their transforms and custom data for the shader
	for i in clouds.size():
		var cloud = clouds[i]
		var depth = cloud["depth"]
		var base_pos = cloud["base_pos"]	
		mmi.multimesh.set_instance_transform_2d(i, Transform2D(0.0, base_pos))
		var uv = CLOUD_UVS[randi() % CLOUD_UVS.size()]
		mmi.multimesh.set_instance_custom_data(i, Color(depth, uv.position.x, uv.position.y, randf()))

func _process(delta):
	# Update shader parameters for camera offset and world size
	_mat.set_shader_parameter("camera_offset", camera.global_position)
	_mat.set_shader_parameter("world_size", world_size)
	_wind_accumulator += wind_velocity * delta
	_mat.set_shader_parameter("wind_offset", _wind_accumulator)

## Helper function to convert a world Y coordinate to a screen UV coordinate (0-1) for shader use
func world_y_to_screen_uv(world_y: float) -> float:
	var viewport_height = get_viewport_rect().size.y
	var screen_y = world_y - camera.global_position.y + viewport_height * 0.5
	return screen_y / viewport_height
