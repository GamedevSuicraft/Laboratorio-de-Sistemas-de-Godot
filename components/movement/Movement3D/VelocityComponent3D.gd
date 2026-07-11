class_name VelocityComponent3D extends Node

@export var speed: float = 10.0
@export var jump_velocity: float = 5.0
@export var gravity_multiplier: float = 1.0


func move_and_jump(body: CharacterBody3D, direction: Vector3, jump_pressed: bool, delta: float) -> void:
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier
	
	# Apply gravity
	if not body.is_on_floor():
		body.velocity.y -= gravity * delta
	
	# Jump
	if jump_pressed and body.is_on_floor():
		body.velocity.y = jump_velocity
	
	# Horizontal movement
	body.velocity.x = direction.x * speed
	body.velocity.z = direction.z * speed
	body.move_and_slide()
