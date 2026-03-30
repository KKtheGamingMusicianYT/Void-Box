extends CharacterBody
class_name Player

@export var BUFFER_JUMP_TIMER : Timer
@export var SFX_PLAYER : PackedScene
@export var CAN_USE_GOD_MODE : bool = false
@export_custom(PROPERTY_HINT_NONE, "suffix: kg") var mass : float = 1
@export_group("Physics HitBoxes")

@export var SMALL_PHYSICS_BOX : CollisionShape2D
var collision_shape : CollisionShape2D

@export_subgroup("Coyote Jumping and Gap Running")
@export var COYOTE_BOX : CollisionPolygon2D
@export var GAP_BOX : CollisionShape2D
@export var GAP_CENSOR : RayCast2D
@export var FLOOR_WALL_CENSOR : ShapeCast2D

@export_subgroup("Edge Clipping")
@export var CLIP_LEFT : RayCast2D
@export var CLIP_RIGHT : RayCast2D
@export var CEILING_SENSOR : ShapeCast2D

@export_group("Health")
@export var HEALTH : int = 2
@export var HITBOX : Area2D

@export_group("Sprites")
@export var CHARACTER_ANIMATED_SPRITE : AnimatedSprite2D

@export_group("Particles")
@export var DEADED_CPU_PARTICLES : CPUParticles2D

var coyot_box_pos : Vector2
var floor_wall_censor_pos : Vector2

var level : PackedScene

enum { # Available states for the Player for readability. Index used by the possibla_states dict to reference paths
	IDLE, # 0
	WALK, # 1
	RUN,
	JUMP,
	FALL,
	GOD_MODE,
	GET_DEADED,
}

func _ready() -> void:
	DEADED_CPU_PARTICLES.emitting = true
	set_physics_process(false)
	
	setup_states()
	coyot_box_pos = COYOTE_BOX.position
	floor_wall_censor_pos = FLOOR_WALL_CENSOR.position
	
	await DEADED_CPU_PARTICLES.finished
	DEADED_CPU_PARTICLES.emitting = false
	set_physics_process(true)
	
	level = load(get_tree().current_scene.scene_file_path)
	
# The conditions for Players to use states
func _physics_process(_delta: float) -> void:
	current_state = state_machine.current_state
	_update_physics_box()
	_handle_player_input()
	move_and_slide()
	_rigid_process()

func _handle_player_input() -> void:
	direction = Input.get_axis("Move_Left", "Move_Right")
	if Input.is_action_just_pressed("Jump"): # Start the BufferJumpTimer when you try to jump
		BUFFER_JUMP_TIMER.start()
	_update_box_dir()
	# Disable gap running
	GAP_BOX.disabled = true
	_match_states()
	if FLOOR_WALL_CENSOR.is_colliding():
		COYOTE_BOX.disabled = true

func _update_box_dir() -> void:
	COYOTE_BOX.position.x = coyot_box_pos.x * direction
	FLOOR_WALL_CENSOR.position.x = floor_wall_censor_pos.x * direction

func _match_states() -> void:
	if not current_state == possible_states[GET_DEADED]:
		_sd()
	match possible_states.find_key(current_state):
		IDLE:
			if direction:
				if Input.is_action_pressed("Run"):
					change_state(RUN)
				else:
					change_state(WALK)
			_check_jumping()
			_check_just_left_floor()
			COYOTE_BOX.disabled = true
			_animate("Idle")
			if Input.is_action_just_released("God_Mode"):
				if CAN_USE_GOD_MODE == true:
					change_state(GOD_MODE)
		WALK:
			_adjust_max_velocity()
			if not direction:
				change_state(IDLE)
			if Input.is_action_pressed("Run"):
				change_state(RUN)
			_check_jumping()
			_check_just_left_floor()
			#_check_gap_running()
			if is_on_floor():
				COYOTE_BOX.disabled = true
			if not GAP_CENSOR.is_colliding():
				direction = 0
			_animate("Walk")
		RUN:
			_adjust_max_velocity()
			if not direction:
				change_state(IDLE)
			if not Input.is_action_pressed("Run"):
				change_state(WALK)
			_check_jumping()
			_check_just_left_floor()
			#_check_gap_running()
			if is_on_floor():
				COYOTE_BOX.disabled = true
			if not GAP_CENSOR.is_colliding():
				direction = 0
			_animate("Walk")
		JUMP:
			if direction:
				_adjust_max_velocity()
			if not Input.is_action_pressed("Jump"):
				jumping = 0
			if jumping < 1:
				change_state(FALL)
			# Clip past corners of the ceiling when you will barely hit it
			#if not CEILING_SENSOR.is_colliding():
			#	_clip_edges(CLIP_RIGHT, -1)
			#	_clip_edges(CLIP_LEFT, 1)
			if is_on_ceiling() and CEILING_SENSOR.is_colliding():
				jumping = 0 # Decelerate your jump
				change_state(FALL) # Start falling
				position.y += 8
				BUFFER_JUMP_TIMER.stop()
			_animate("Idle")
		FALL:
			if direction:
				_adjust_max_velocity()
			if is_on_floor():
				if direction:
					if Input.is_action_pressed("Run"):
						change_state(RUN)
					else:
						change_state(WALK)
				else:
					change_state(IDLE)
			_animate("Idle")
		GOD_MODE:
			var dir_vec2 : Vector2 = Vector2(Input.get_axis("Move_Left", "Move_Right"), Input.get_axis("ui_down", "ui_up"))
			properties.VELOCITY = Vector2(700, -700)
			properties.VELOCITY *= dir_vec2
			if Input.is_action_pressed("God_Mode"):
				change_state(IDLE)
		GET_DEADED:
			velocity = Vector2(0,0)
			CHARACTER_ANIMATED_SPRITE.stop()
			CHARACTER_ANIMATED_SPRITE.visible = false
			DEADED_CPU_PARTICLES.emitting = true

func _check_jumping() -> void:
	jumping = properties.JUMPING_FRAMES
	if Input.is_action_pressed("Jump") and BUFFER_JUMP_TIMER.time_left != 0: # jump if allowed
		change_state(JUMP)
		var new_SFX_PLAYER = SFX_PLAYER.instantiate()
		add_child(new_SFX_PLAYER)
		new_SFX_PLAYER.stop()
		new_SFX_PLAYER.play(0.0)
		await get_tree().create_timer(0.5).timeout
		new_SFX_PLAYER.stop()
		new_SFX_PLAYER.queue_free()

func _check_just_left_floor() -> void:
	if not is_on_floor():
		change_state(FALL)
		#_check_coyote_jumping()

func _check_coyote_jumping() -> void:
	if direction:
		COYOTE_BOX.disabled = false
		_check_jumping()
	else: # If you aren't holding a direction, are you trying to Coyote Jump? No.
		COYOTE_BOX.disabled = true
	# Be sure CoyoteBox is enabled when needed; this will keep it from bugging out
	if COYOTE_BOX.disabled == false:
		_adjust_max_velocity()

func _check_gap_running() -> void:
	# Allow for running over small gaps
	if not GAP_CENSOR.is_colliding() and abs(velocity.x) > properties.WALKING_SPEED and FLOOR_WALL_CENSOR.is_colliding():
		GAP_BOX.disabled = false

func _sd() -> void:
	if Input.is_action_just_released("Get_Deaded"):
		change_state(GET_DEADED)
		var new_SFX_PLAYER = SFX_PLAYER.instantiate()
		add_child(new_SFX_PLAYER)
		new_SFX_PLAYER.play(0.81)
		SwitchScene.switch_to(level.resource_path, 3)

func _adjust_max_velocity() -> void:
	# The JUMP and FALL states use VELOCITY.x to determine sideways movement, 
	# so set the VELOCITY.x to the RUNNING/WALKING_SPEED when needed to carry momentum
	if Input.is_action_pressed("Run"):
		properties.VELOCITY.x = properties.RUNNING_SPEED
	else:
		properties.VELOCITY.x = properties.WALKING_SPEED

func _clip_edges(clip_ray : RayCast2D, dir : int) -> void:
	if clip_ray.is_colliding():
		if clip_ray.get_collider() is not TileData:
			return
		var _collision_point : Vector2 = clip_ray.get_collision_point()/64
		print(clip_ray.get_collision_point())
		if clip_ray == CLIP_LEFT:
			_collision_point = ceil(_collision_point) * 64
		if clip_ray == CLIP_RIGHT:
			_collision_point = floor(_collision_point) * 64
		
		position.x = _collision_point.x + (32 * dir) + (-dir * (64 - collision_shape.shape.get_rect().size.x)/2) + dir

func _update_physics_box() -> void:
		SMALL_PHYSICS_BOX.disabled = false
		collision_shape = SMALL_PHYSICS_BOX 
		
func _animate(animation: String) -> void:
	CHARACTER_ANIMATED_SPRITE.play(animation)
	if direction:
		CHARACTER_ANIMATED_SPRITE.flip_h = direction*-1+1

func _rigid_process() -> void:
	match possible_states.find_key(current_state):
		IDLE:
			_push_rigid_bodies()
		WALK:
			_push_rigid_bodies()
		RUN:
			_push_rigid_bodies()

func _push_rigid_bodies() -> void:
	for collision_number in get_slide_collision_count():
		var collision = get_slide_collision(collision_number)
		if collision.get_collider() is RigidBody2D:
			direction = Input.get_axis("Move_Left", "Move_Right")
			var collider : RigidBody2D = collision.get_collider()
			collider.apply_central_force(
				Vector2(collision.get_normal().x * -1 * mass * properties.VELOCITY.x, 0)
			)
