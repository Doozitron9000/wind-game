extends MultiMeshInstance2D

# the maximum distance a particle can be from the viewer
const MAX_Z : float = 0.5
# how fast particles should move relative tot he wind vector
const SPEED_MODIFIER : float = 1.5

# The bounding box of the wind zone in global space
var padded_bounds : Rect2

# collision polygon area that defines the wind zone's area
@onready var collision : CollisionPolygon2D = $".."
# the parent object of the whole zone
@onready var zone : Area2D = $"../.."
# the mask viewport used to determine if a particle is visible
@onready var mask : Sprite2D = $"../Mask"

## on start determine the bounding box and place all the particles
## in their start positions
func _ready() -> void:
	# initialize the bounding box and the particle positions
	# this must be deferred since the collision shape isn't
	# known until run time
	call_deferred("initialize")
	
## every frame update each particle's position
func _process(delta: float) -> void:
	move_particles(delta)

## defines the bounding box and initial position of every particle
func initialize() -> void:
	# get the bounds of the wind zone
	padded_bounds = zone.get_padded_bounds()
	# get the particle count
	multimesh.instance_count = zone.get_particle_count()
	# set the initial position of each particles
	position_particles()
	
## set the initial position of every particles
func position_particles() -> void:
	var angle : float = zone.wind.angle()
	# position each particle randomly within said the bounding box
	for i in range(multimesh.instance_count):
		var spawn_global := Vector2(
			randf_range(padded_bounds.position.x, padded_bounds.position.x + padded_bounds.size.x),
			randf_range(padded_bounds.position.y, padded_bounds.position.y + padded_bounds.size.y)
		)

		# Multimesh instances operate in local space so we need to convert
		# our spawn point to that before applying it
		var spawn_local = to_local(spawn_global)
		
		# create the transform to apply to the instance, rotate it,
		# and apply it
		var trans := Transform2D(angle, spawn_local)
		trans.origin = spawn_local
		multimesh.set_instance_transform_2d(i, trans)
		
		# now give this particle a random depth
		var z_range : float = 1.0-MAX_Z
		var depth := pow(randf(), 2.0) * z_range + MAX_Z
		multimesh.set_instance_custom_data(i, Color(0.0, 0.0, depth, 0.0))

## Sets up the params for the particle shader. These are used to determine
## which partciles should be masked
func bind_shader_parameters() -> void:
	# get the material
	var mat : ShaderMaterial = material as ShaderMaterial
	# bind the wind speed
	material.set_shader_parameter("wind_speed", zone.wind_speed)
	# bind the mask texture
	mat.set_shader_parameter(
		"mask_tex",
		mask.get_texture()
	)
	# bind the global bounds
	mat.set_shader_parameter(
		"bounds_pos",
		padded_bounds.position
	)
	# bind the bounds size
	mat.set_shader_parameter(
		"bounds_size",
		padded_bounds.size
	)

func move_particles(delta: float) -> void:
	# get the wind direction
	var wind_dir : Vector2 = zone.wind
	# get the wind total and just return if it's zero
	var wind_total : float = abs(wind_dir.x) + abs(wind_dir.y)
	if (wind_total == 0): return
	# rather than calculating which sides we should be spawning on, the sides we 
	# should wrap after crossing, the wind direction, and the height and width
	# for each instance lets just get all that here and re-use it
	# height and width
	var zone_width : float = padded_bounds.size.x
	var zone_height : float = padded_bounds.size.y
	# wind direction
	var wind_right : bool = wind_dir.x > 0
	var wind_down : bool = wind_dir.y > 0
	# "near" and "far" side relative to wind direction
	var near_x : float
	var far_x : float
	var near_y : float
	var far_y : float
	if wind_right:
		near_x = padded_bounds.position.x
		far_x = padded_bounds.position.x + zone_width
	else:
		near_x = padded_bounds.position.x + zone_width
		far_x = padded_bounds.position.x
	
	if wind_down:
		near_y = padded_bounds.position.y
		far_y = padded_bounds.position.y + zone_height
	else:
		near_y = padded_bounds.position.y + zone_height
		far_y = padded_bounds.position.y
	
	# It's possible an instance crosses both the bound's left and right side
	# at the same time. If this happens and we just wrap it around the first
	# axis we check we will slowly get an uneven distribution of particles,
	# particularly if we are lagging or the wind is very fast. To counter this,
	# we respawn particles on a weighted (based on the wind direction)
	# random side not the opposite of the side crossed. To this end, let's
	# calculate the percentage of the wind's move vector that's along the x axis
	var wind_x_per : float = abs(wind_dir.x)/wind_total
	
	# move every particle in the wind direction
	for i in range(multimesh.instance_count):
		# get the global position of the instance so we can more easily
		# compare it to our bounding box
		var trans : Transform2D = multimesh.get_instance_transform_2d(i)
		var pos_local : Vector2 = trans.origin
		var pos_global = to_global(pos_local)

		# calculate the new position of this instance accounting for z
		var z : float = multimesh.get_instance_custom_data(i).b
		pos_global += wind_dir * delta * z * SPEED_MODIFIER
		
		# check if we should wrap
		var should_wrap : bool = ((wind_right and pos_global.x > far_x) or
							(!wind_right and pos_global.x < far_x) or
							(wind_down and pos_global.y > far_y) or
							(!wind_down and pos_global.y < far_y))
		
		if should_wrap:
			# randomly determine a side to wrap on and then reposition
			var wrapping_x : bool = randf() <= wind_x_per
			if wrapping_x:
				pos_global.x = near_x
				pos_global.y = randf_range(near_y, far_y)
			else:
				pos_global.y = near_y
				pos_global.x = randf_range(near_x, far_x)

		# now convert the position back to local and apply it as a transform
		pos_local = to_local(pos_global)
		trans.origin = pos_local
		multimesh.set_instance_transform_2d(i, trans)
