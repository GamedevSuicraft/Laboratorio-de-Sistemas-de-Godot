class_name PressurePlateLogic
extends Area3D

## Emitted when a CharacterBody3D enters or leaves the detection area.
signal pressed
signal released

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		pressed.emit()

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		released.emit()
