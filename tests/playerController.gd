extends CharacterBody2D

@onready var health: HealthComponent = $HealthComponent
@onready var inventory: InventoryComponent = $InventoryComponent
@onready var movement: PlatformerMovementComponent = $PlatformerMovementComponent

func _physics_process(delta: float) -> void:
	var direction_x = Input.get_axis("ui_left", "ui_right")
	var jump_pressed = Input.is_action_just_pressed("ui_accept")
	movement.move_and_jump(self, direction_x, jump_pressed, delta)
