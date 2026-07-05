class_name TopDownMovementComponent extends Node

@export var speed: float = 200.0

func move(body: CharacterBody2D, direction: Vector2):
	body.velocity = direction.normalized() * speed
	body.move_and_slide()
