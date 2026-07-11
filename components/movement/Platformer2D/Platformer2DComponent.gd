@icon("./platformer_movement.svg")
class_name Platformer2DComponent extends Node

@export var speed: float = 200.0
@export var jump_velocity: float = 1000.0
@export var gravity_multiplier: float = 1.0


func move_and_jump(body: CharacterBody2D, direction_x: float, jump_pressed: bool, delta: float) -> void:
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_multiplier
	
	# Apply gravity
	if not body.is_on_floor():
		body.velocity.y += gravity * delta
	
	# Jump
	if jump_pressed and body.is_on_floor():
		body.velocity.y = -jump_velocity
		print(body.velocity.y)
	
	# Horizontal movement
	body.velocity.x = direction_x * speed
	body.move_and_slide()
