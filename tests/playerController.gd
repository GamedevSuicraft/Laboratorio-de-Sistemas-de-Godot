extends CharacterBody2D

@export var speed: float = 200

@export_group("References")
@export var inventory: InventoryComponent
@export var movement: Platformer2DComponent
@export var interactor: Interactor2D


func _ready() -> void:
	movement.speed = speed


func _physics_process(delta: float) -> void:
	var direction_x = Input.get_axis("ui_left", "ui_right")
	var jump_pressed = Input.is_action_just_pressed("ui_accept")
	movement.move_and_jump(self, direction_x, jump_pressed, delta)
	print(movement.speed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interactor.try_interaction(self)
