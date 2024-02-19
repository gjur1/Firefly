extends State

@export_subgroup("TRANSITIONAL STATES")
@export var AERIAL_STATE: State = null

# And check the jump buffer on landing
@export_subgroup("Input Assists")
@export var jump_buffer: Timer
@export var coyote_time: Timer



# GROUNDED
@onready var dust = $"../../DashDust"

#@onready var dust_scene = preload("res://Scenes/Player/particles/jump_dust.tscn")
#var scene_instance = scene.instance()
#scene_instance.set_name("scene")
#add_child(scene_instance)


# Called on state entrance, setup
func enter() -> void:
	print("Grounded State")
	
	#if Input.is_action_pressed("Down"):
		#parent.current_animation = parent.ANI_STATES.CROUCH
	#else:	
	parent.current_animation = parent.ANI_STATES.LANDING
	
	# Give dust on landing
	var new_cloud = parent.LANDING_DUST.instantiate()
	new_cloud.set_name("landing_dust_temp")
	$"../../LandingDustSpawner".add_child(new_cloud)
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")

# Called before exiting the state, cleanup
func exit() -> void:
	# This is hard because we could either be falling or jumping in leaving this state
	# So lets be silly how we handle that
	coyote_time.start()
	pass

# Processing input in this state, returns nil or new state
func process_input(event: InputEvent) -> State:
	return null


# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> State:
	
	
	var new_state: State =  null
	
	new_state = jump_logic(delta, parent.horizontal_axis)
	#if new_state:
		#return new_state
	
	handle_acceleration(delta, parent.horizontal_axis)
	apply_friction(delta, parent.horizontal_axis)
	
	
	parent.move_and_slide()
	
	update_state(parent.horizontal_axis)
	
	# Make Sure we're still grounded after this
	if not parent.is_on_floor():
		return AERIAL_STATE
		
	return null
	
# TODO: Add jump lag in order to show the crouch animation
func jump_logic(delta, direction) -> State:
	
	if Input.is_action_just_pressed("Jump") or jump_buffer.time_left > 0.0:
		
		
		var new_cloud = parent.JUMP_DUST.instantiate()
		new_cloud.set_name("jump_dust_temp")
		$"../../JumpDustSpawner".add_child(new_cloud)
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")
		
		
		# Prevent silly interactions between jumping and wall jumping
		jump_buffer.stop()
		jump_buffer.wait_time = -1
		
		print("Jump Math")
		parent.velocity.y = parent.movement_data.JUMP_VELOCITY
		
		
		# If we're not currently crouching, then we initiate jumping
		if (parent.current_animation != parent.ANI_STATES.CRAWL):
			parent.current_animation = parent.ANI_STATES.FALLING
			
		
		
			
	return null
	

	
	

func handle_acceleration(delta, direction):
	
	
	# Can't move forward when crouching or landing
	if direction:  
		if parent.current_animation != parent.ANI_STATES.CRAWL and parent.current_animation != parent.ANI_STATES.CROUCH:
			parent.velocity.x = move_toward(parent.velocity.x, parent.movement_data.SPEED*direction, parent.movement_data.ACCEL * delta)
	
func apply_friction(delta, direction):
	
	# Ok this makes the game really slippery when changing direction
	if direction == 0:
			parent.velocity.x = move_toward(parent.velocity.x, 0, parent.movement_data.FRICTION*delta)
		
			
	elif not direction * parent.velocity.x > 0:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.movement_data.TURN_FRICTION*delta)
		
# Updates animation states based on changes in physics
func update_state(direction):
	
	# Change direction
	if direction > 0:
		parent.animation.flip_h = false
		#dust.gravity.x = -200
	elif direction < 0:
		parent.animation.flip_h = true
		#dust.gravity.x *= 200
	
	# If set to running/walking from grounded state
	if direction:
		if parent.current_animation == parent.ANI_STATES.IDLE or parent.current_animation == parent.ANI_STATES.RUNNING or parent.current_animation == parent.ANI_STATES.WALKING:
			if abs(parent.velocity.x) >= parent.movement_data.RUN_THRESHOLD:
				parent.current_animation = parent.ANI_STATES.RUNNING
				dust.emitting = true
			else:
				parent.current_animation = parent.ANI_STATES.WALKING
			
	# Set to idle from walking
	if not direction:
		if (parent.current_animation == parent.ANI_STATES.RUNNING or parent.current_animation == parent.ANI_STATES.WALKING) :
			parent.current_animation = parent.ANI_STATES.IDLE
	
	# So if we are in falling and we've touched the floor aggresively finish the animation
	#if animation_state == STATE.FALLING and is_on_floor():
	#	animated.speed_scale = 2.0
		
		
	# Crawling Shit
	# When we press down we crouch
	if Input.is_action_just_pressed("Down") and parent.current_animation != parent.ANI_STATES.CRAWL:
		parent.current_animation = parent.ANI_STATES.CROUCH
		
	# Stay there til we let go of down
	if (parent.current_animation == parent.ANI_STATES.CRAWL) and not Input.is_action_pressed("Down"):
		parent.current_animation = parent.ANI_STATES.STANDING_UP
		
	if parent.current_animation != parent.ANI_STATES.RUNNING:
		dust.emitting = false
		
func animation_end() -> State:
	
	# If we've stopped landing then we go to idle animations
	if parent.current_animation == parent.ANI_STATES.LANDING:
		parent.current_animation = parent.ANI_STATES.IDLE
		
	# If we've finished crouching then we go to our crawl
	if parent.current_animation == parent.ANI_STATES.CROUCH:
		parent.current_animation = parent.ANI_STATES.CRAWL
	
	if parent.current_animation == parent.ANI_STATES.CRAWL:
		print("Thing set")
	
	# If we've stopped getting up then we go to our idle
	if parent.current_animation == parent.ANI_STATES.STANDING_UP:
		parent.current_animation = parent.ANI_STATES.IDLE
	
	return null