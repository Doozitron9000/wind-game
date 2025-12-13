# This windzone works by applying its wind vector to any "wind_affected" object
# that enters it and removing the wind influence on an object when it exits.
# All wind_affected objects MUST be given a wind var or this will not work.

# To use this scene add it to a level and set its children to be editable
# (Right click and enable editable children). THen resize the contained
# collision polygon as you see fit.
extends Area2D

# the speed at which our particle count will math the particles per 1000px
# value. Below this speed fewer particles will be shown and above it more
# will be. This is const for now since particle count can still be controlled
# using the per 1000px value
const BASE_SPEED : float = 100.0
# TEMP PADDING CONSTANT TO BE REPLACED LATER
const PADDING : float = 20.0

# get the multimesh instance responsible for the wind particles
@onready var particles : MultiMeshInstance2D = $Collision/Particles
# get both the visual and collision elements
@onready var visuals : Polygon2D = $MaskViewport/VisibleArea
# the collision polygon. THis is the source of truth when it comes to the
# shape of the wind area with everything else matching it
@onready var collision : CollisionPolygon2D = $Collision
# everything for generating and using the mask texture
# the three viewports to create and blur the texture
@onready var hard_mask : SubViewport = $MaskViewport
@onready var h_blur_mask : SubViewport = $HorizontalMaskBlur
@onready var h_blur_sprite : Sprite2D = $HorizontalMaskBlur/HoriztonalBlur
@onready var v_blur_mask : SubViewport = $VerticalMaskBlur
@onready var v_blur_sprite : Sprite2D = $VerticalMaskBlur/VerticalBlur
# the sprite on which to store the texture
@onready var mask_sprite : Sprite2D = $Collision/Mask

# the current speed of the wind
var wind_speed : float

# The vector representing the wind direction and magnitude
@export var wind : Vector2:
	# setter also updates wind speed
	set(value):
		wind = value
		wind_speed = wind.length()
# the base number of particles per 1000 square pixels
@export var particles_per_1000px2 : float = 1.0

func _ready() -> void:
	set_mask()

## When a body enters this it has the wind applied to it
## if applicable
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("wind_affected"):
		body.wind = wind

## When a body exits  this it has the wind removed from it
## if applicable..... IF we end up having overlapping windzones
## this will be a problem and will need to be addressed
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("wind_affected"):
		body.wind = Vector2.ZERO
		
## gets the bounding box of the wind zone
func get_global_bounds() -> Rect2:
	# make default values extreme so the first point
	# will always overwrite them
	var min_x : float = INF
	var min_y : float = INF
	var max_x : float = -INF
	var max_y : float = -INF
	
	# now iterate through every point in the collision polygon
	# and figure out which is highest, lowest, leftmost, and rightmost,
	# so we can determine the bounding box
	for point in collision.polygon:
		var global_point = collision.to_global(point)
		min_x = min(min_x, global_point.x)
		max_x = max(max_x, global_point.x)
		min_y = min(min_y, global_point.y)
		max_y = max(max_y, global_point.y)
	
	# calculate the height and width of the bounding box
	var width : float = max_x-min_x
	var height : float = max_y-min_y
	
	# now create and return the bounding box
	return Rect2(Vector2(min_x, min_y), Vector2(width, height))

## gets the global bounds of the rect with padding around it for use
## when calculating particle visibility etc
func get_padded_bounds() -> Rect2:
	# first get the global bounds so we can pad it
	var global_bounds : Rect2 = get_global_bounds()
	# now add the padding to the global bounds anre return it
	global_bounds.size.x += PADDING*2
	global_bounds.size.y += PADDING*2
	global_bounds.position.x -= PADDING
	global_bounds.position.y -= PADDING
	# and finally return the newly padded bounds
	return global_bounds

## Gets the shape of this wind zone
func get_local_shape() -> PackedVector2Array:
	return collision.polygon
	
## Gets the shape of this wind zone
func get_global_shape() -> PackedVector2Array:
	# make a repased version of the collision poly in global space
	var rebased_polygon : PackedVector2Array = PackedVector2Array()
	var global_bounds := get_global_bounds()
	# so iterate through every vector in our collision poly converting them
	# into global space before returning our new global polygon
	for point : Vector2 in collision.polygon:
		var global_point : Vector2 = collision.to_global(point)
		rebased_polygon.append(global_point - global_bounds.position)
		
	return rebased_polygon

## Gets the padded shape of this wind zone (so the shape where the relative
## position of each vector accounts for padding)
func get_padded_shape() -> PackedVector2Array:
	# make a repased version of the collision poly in global space
	var rebased_polygon : PackedVector2Array = PackedVector2Array()
	var padded_bounds := get_padded_bounds()
	# so iterate through every vector in our collision poly converting them
	# into global space before returning our new global polygon
	for point : Vector2 in collision.polygon:
		var global_point : Vector2 = collision.to_global(point)
		rebased_polygon.append(global_point - padded_bounds.position)
		
	return rebased_polygon

## gets the number of particles in this zone. This should include padding
## in the total area to keep particles count consistent with expectations
func get_particle_count() -> int:
	# calculate the number of particles based on the global bounds
	var padded_bounds : Rect2 = get_padded_bounds()
	var area = padded_bounds.size.x * padded_bounds.size.y
	var count : float = (area * (particles_per_1000px2 / 1000.0) *
						wind_speed / BASE_SPEED)
	# limit us to having at least on particle and round to nearest rather
	# than down
	return max(1, int(round(count)))

# handles the construction and assignment of the particle mask as well as the
# removal of excess subviewports
func set_mask() -> void:
	# get the bounds 
	var padded_bounds := get_padded_bounds()
	# now set the size of all the mask viewports
	hard_mask.size = padded_bounds.size
	h_blur_mask.size = padded_bounds.size
	v_blur_mask.size = padded_bounds.size
	# assign the blurred sprites their textures. NOTE these haven't
	# necessarily generated so these sprites likely not fully set yet
	h_blur_sprite.texture = hard_mask.get_texture()
	v_blur_sprite.texture = h_blur_mask.get_texture()

	# now we need to await each sub-viewport to draw one by one givine each
	# a frame to draw
	
	# hard mask
	hard_mask.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	# horizontal blur
	h_blur_mask.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	# vertical blur
	v_blur_mask.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	# now everything should be generated so we can generate the image texture
	# and assign it
	var rid := v_blur_mask.get_texture().get_rid()
	var img : Image = RenderingServer.texture_2d_get(rid)
	var tex : ImageTexture = ImageTexture.create_from_image(img)

	mask_sprite.texture = tex

	# and finally we can now remove the subviewports
	hard_mask.queue_free()
	h_blur_mask.queue_free()
	v_blur_mask.queue_free()
	
	# now we know all this is generated we can bind the shader params
	# of our particle system
	particles.bind_shader_parameters()
