@icon("./platformer_movement.svg")
class_name Platformer2DComponent extends Node

@export_group("Movement Settings")
@export var speed: float = 200.0
@export var jump_velocity: float = 1000.0
@export var gravity_multiplier: float = 1.0

@export_group("Game Feel")
## The time window (in seconds) the player is allowed to jump after leaving a ledge.
@export var coyote_time: float = 0.15

## The time window (in seconds) that stores a jump input if pressed shortly before landing.
@export var jump_buffer_time: float = 0.15

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0


func move_and_jump(body: CharacterBody2D, direction_x: float, jump_pressed: bool, delta: float) -> void:
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_multiplier
	
	# 1. Update Coyote Timer (tolerance window after leaving floor)
	if body.is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta
	
	# 2. Update Jump Buffer Timer (records jump intent shortly before landing)
	if jump_pressed:
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta
	
	# 3. Apply gravity
	if not body.is_on_floor():
		body.velocity.y += gravity * delta
	
	# 4. Jump Execution (checks if both inputs are valid and buffered)
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		body.velocity.y = -jump_velocity
		
		# Consume both timers immediately to prevent double-jumping in mid-air
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
	
	# 5. Apply Horizontal movement
	body.velocity.x = direction_x * speed
	body.move_and_slide()
