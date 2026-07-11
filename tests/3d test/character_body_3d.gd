extends CharacterBody3D


@export_group("References")
@export var movement: VelocityComponent3D
@export var interactor: Interactor3D


func _physics_process(delta: float) -> void:
	var jump_pressed = Input.is_action_just_pressed("ui_accept")
	var direction = Vector3(
		Input.get_axis("ui_left", "ui_right"),
		1,
		Input.get_axis("ui_up", "ui_down")
	)
	movement.move_and_jump(self, direction, jump_pressed, delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		print("tentou interagir")
		interactor.try_interaction(self)
