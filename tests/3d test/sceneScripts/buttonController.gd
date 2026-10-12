extends Node3D

enum ButtonState {
	UNPRESSED = 0,
	PRESSED = 1
}

@export var buttonState: ButtonState = ButtonState.UNPRESSED


func _on_area_3d_pressed() -> void:
	pass # Replace with function body.


func _on_area_3d_released() -> void:
	pass # Replace with function body.
