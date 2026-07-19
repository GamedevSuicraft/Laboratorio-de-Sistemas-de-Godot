## Handles 3D movement, gravity, and jumping calculations for a CharacterBody3D.
##
## To use:
## 1. Add this component as a child of a CharacterBody3D node.
## 2. (Optional) Set the movement_reference to a camera or pivot node for direction-relative movement.
## 3. Call move_and_jump() inside the parent's _physics_process().
class_name VelocityComponent3D extends Node

## The movement speed of the character in units per second.
@export var speed: float = 10.0

## The vertical velocity applied to the character when jumping.
@export var jump_velocity: float = 5.0

## Multiplier applied to the default project gravity settings.
@export var gravity_multiplier: float = 1.0

## The Node3D used as a directional pivot (e.g., ThirdPersonCamera) to orient the input direction.
@export var movement_reference: Node3D

@export_group("Game Feel")
## The time window (in seconds) the player is allowed to jump after leaving a ledge.
@export var coyote_time: float = 0.15
## The time window (in seconds) that stores a jump input if pressed shortly before landing.
@export var jump_buffer_time: float = 0.15

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0


func move_and_jump(body: CharacterBody3D, input_vector: Vector3, jump_pressed: bool, delta: float) -> void:
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier
	
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
	
	var direction = Vector3.ZERO
	if movement_reference:
		var forward = movement_reference.global_transform.basis.z
		var right = movement_reference.global_transform.basis.x
		
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		
		direction = (forward * input_vector.z) + (right * input_vector.x)
	else:
		direction = Vector3(input_vector.x, 0, input_vector.z)
	
	# Apply gravity
	if not body.is_on_floor():
		body.velocity.y -= gravity * delta
	
	# 3. Jump Execution (checks if both inputs are valid and buffered)
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		body.velocity.y = jump_velocity
		
		# Consume both timers immediately to prevent double-jumping in mid-air
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
	
	# Horizontal movement
	var target_velocity = direction * speed
	body.velocity.x = target_velocity.x
	body.velocity.z = target_velocity.z
	
	body.move_and_slide()
