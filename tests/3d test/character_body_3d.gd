extends CharacterBody3D

@export_group("Parameters")
@export var walk_speed := 10.0
@export var sprint_speed := 20.0
@export var running_stamina_cost: float = 10.0

@export_group("References")
@export var movement: VelocityComponent3D
@export var interactor: Interactor3D
@export var camera_pivot: ThirdPersonCamera
@export var stamina: ResourceComponent


func _physics_process(delta: float) -> void:
	if Input.is_key_pressed(KEY_SHIFT) and stamina.consume_over_time(running_stamina_cost, delta):
		movement.speed = sprint_speed
	else:
		movement.speed = walk_speed
	
	var jump_pressed = Input.is_action_just_pressed("ui_accept")
	var direction = Vector3(
		Input.get_axis("ui_left", "ui_right"),
		1,
		Input.get_axis("ui_up", "ui_down")
	)
	movement.move_and_jump(self, direction, jump_pressed, delta)
	
	if camera_pivot and camera_pivot.has_method("set_movement_vector"):
		camera_pivot.set_movement_vector(velocity)



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		print("tentou interagir")
		interactor.try_interaction(self)
