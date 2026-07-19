## Handles basic top-down horizontal and vertical 2D movement for a CharacterBody2D.
##
## To use:
## 1. Add this component as a child of a CharacterBody2D node.
## 2. Configure the movement speed in the inspector.
## 3. Call move() inside the parent's _physics_process() passing the movement input vector.
@icon("./rpg_movement.svg")
class_name TopDown2DComponent extends Node

## The movement speed of the character in pixels per second.
@export var speed: float = 200.0

func move(body: CharacterBody2D, direction: Vector2):
	body.velocity = direction.normalized() * speed
	body.move_and_slide()
