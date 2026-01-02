extends Node
# the maximum number of clouds
const MAX_DENSITY : float = 300
# preload the cloud texture atlas so we only load it into memory once not
# per cloud
const ATLAS : Texture2D = preload("res://assets/background/Clouds.png")
# the min z value of a standard cloud
const MIN_DISTANCE : float = 0.9

# the cloud density and the direction the clouds should move
# 0 = no clouds, 1 = max clouds
@export_range(0.0, 1.0, 0.01) var cloud_density : float = 1.0
@export var wind_direction : Vector2 = Vector2.ZERO
# get the level dimensions........ this must be the entire bounding box that
# the camera can display not just the traversable area
@export var camera_zone : Rect2
# the band clouds exist within as well as their vanishing point
@export var cloud_band_height : float
@export var vanishing_point : float
@export var cloud_band_width : float
# the clouds in the nearest parallax layer
var clouds : Array[Sprite2D] = []

# the active camera
@onready var camera = get_viewport().get_camera_2d()

# on ready generate the clouds
func _ready() -> void:
	var cloud_count : int = int(MAX_DENSITY*cloud_density)
	
	for i in range(cloud_count):
		# make a var to store the spawn pos
		var spawn_pos : Vector2 = Vector2.ZERO
		# now randomly generate it
		# generate random coords for the sprite
		spawn_pos.x = randf() * camera_zone.size.x + camera_zone.position.x
		# get the depth of the cloud. We want these to be disproportionately
		# distance so square them
		var depth = 1 - randf() ** 2
		# get the effective width once z is accounted for
		var effective_width : float = cloud_band_width*(1-depth)
		# we need to get our effective middle at this depth
		var effective_middle = lerp(cloud_band_height, vanishing_point, depth)
		# get the width of the y band for this cloud
		var cloud_band_top : float = effective_middle - effective_width*0.5
		# use depth to determine y position after applying perspective
		spawn_pos.y = effective_width * randf() + cloud_band_top
		# spawn the cloud now limiting depth within it's constraints
		spawn_cloud(spawn_pos, depth)
	
# move the clouds every frame
func _process(delta: float) -> void:
	# get the width of the viewport and its location
	var camera_pos = camera.global_position
	# iterate throught the clouds moving them
	for cloud in clouds:
		# get the cloud's current position
		# get the bounds of the area beyond which we should delete... so
		# the camera area + the cloud dimesnsions
		var half_width = cloud.dimensions.x / 2
		var half_height = cloud.dimensions.y / 2
		var left : float = camera_zone.position.x - half_width
		var right : float = left + camera_zone.size.x + half_width
		var top : float = camera_zone.position.y - half_height
		var bottom : float = top + camera_zone.size.y + half_height
		# check if the cloud is outside the bounds and if so wrap it
		if cloud.origin.x < left:
			cloud.origin.x = right
		elif cloud.origin.x > right:
			cloud.origin.x = left
		elif cloud.origin.y < top:
			cloud.origin.y = bottom
		elif cloud.origin.y > bottom:
			cloud.origin.y = top
		# get the clouds scaled wind
		var wind = wind_direction * (1-cloud.z) * delta
		# update the origin point by wind
		cloud.origin = cloud.origin + wind
		cloud.global_position.x = cloud.origin.x + camera_pos.x * cloud.z
		cloud.global_position.y = cloud.origin.y + camera_pos.y * cloud.z
		

func spawn_cloud(spawn_position : Vector2, depth : float) -> void:
	var sprite : Cloud = Cloud.new()
	# add the texture atlas to the new cloud
	var texture : AtlasTexture = AtlasTexture.new()
	texture.atlas = ATLAS
	# randomly determine the cloud type
	var type := randi() % 6
	# check if type is tall and if so spawn a tall cloud
	var tall : bool = type > 3
	# make a var to store the dimensions of this cloud
	var dimensions : Vector2 = Vector2.ZERO
	if tall:
		type -= 3
		texture.region = Rect2(512, 512*type, 512, 512)
		dimensions = Vector2(512,512)
	# otherwise spawn a short cloud
	else :
		texture.region = Rect2(0, 256*type, 512, 256)
		dimensions = Vector2(512,256)
	
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# this will be easier if we thing of sprites by their centers no tops.
	sprite.centered = true
	# and our new sprite to the nearest plane
	add_child(sprite)
	# the scale of the the cloud in question
	var scale = clamp(1-depth, 0.3, 1)
	sprite.z = depth * (1-MIN_DISTANCE) + MIN_DISTANCE
	sprite.dimensions = dimensions * scale
	sprite.scale = Vector2(scale, scale)
	sprite.origin = spawn_position
	clouds.append(sprite)
