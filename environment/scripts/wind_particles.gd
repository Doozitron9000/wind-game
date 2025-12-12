extends MultiMeshInstance2D

# The bounding box of the wind zone in global space
var global_bounds : Rect2

# collision polygon area that defines the wind zone's area
@onready var collision : CollisionPolygon2D = $".."
# the parent object of the whole zone
@onready var zone : Area2D = $"../.."
# the mask viewport used to determine if a particle is visible
@onready var mask : SubViewport = $"../../MaskViewport"

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
	global_bounds = zone.get_global_bounds()
	# set the mask texture for the particles to they mask viewport
	bind_shader_parameters()
	# position each particle randomly within said the bounding box
	for i in range(multimesh.instance_count):
		var spawn_global := Vector2(
			randf_range(global_bounds.position.x, global_bounds.position.x + global_bounds.size.x),
			randf_range(global_bounds.position.y, global_bounds.position.y + global_bounds.size.y)
		)

		# Multimesh instances operate in local space so we need to convert
		# our spawn point to that before applying it
		var spawn_local = to_local(spawn_global)
		
		# create the transform to apply to the instance
		# and apply it
		var trans := Transform2D()
		trans.origin = spawn_local
		multimesh.set_instance_transform_2d(i, trans)

## binds the relavent vars to the shaders params
func bind_shader_parameters() -> void:
	# get the material
	var mat : ShaderMaterial = material as ShaderMaterial
	# bind the mask texture
	mat.set_shader_parameter(
		"mask_tex",
		mask.get_texture()
	)
	# bind the global bounds
	mat.set_shader_parameter(
		"bounds_pos",
		global_bounds.position
	)
	# bind the bounds size
	mat.set_shader_parameter(
		"bounds_size",
		global_bounds.size
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
	var zone_width : float = global_bounds.size.x
	var zone_height : float = global_bounds.size.y
	# wind direction
	var wind_right : bool = wind_dir.x > 0
	var wind_down : bool = wind_dir.y > 0
	# "near" and "far" side relative to wind direction
	var near_x : float
	var far_x : float
	var near_y : float
	var far_y : float
	if wind_right:
		near_x = global_bounds.position.x
		far_x = global_bounds.position.x + zone_width
	else:
		near_x = global_bounds.position.x + zone_width
		far_x = global_bounds.position.x
	
	if wind_down:
		near_y = global_bounds.position.y
		far_y = global_bounds.position.y + zone_height
	else:
		near_y = global_bounds.position.y + zone_height
		far_y = global_bounds.position.y
	
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

		# calculate the new position of this instance
		pos_global += wind_dir * delta
		
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
