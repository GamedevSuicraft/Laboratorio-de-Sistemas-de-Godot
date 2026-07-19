## 3D third-person camera controller using a SpringArm3D to prevent clipping.
##
## To use:
## 1. Add this Node3D to the Player scene.
## 2. Customize mouse sensitivity, spring arm length, and rotation angle constraints in the inspector.
## 3. The node automatically captures mouse movement to rotate the camera around the player.
@icon("./camera.svg")
class_name ThirdPersonCamera extends Node3D

@export_group("Camera Settings")

## Mouse sensitivity multiplier for camera rotation.
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25

## Length of the SpringArm3D offset from the target.
@export var spring_length: float = 8.0

@export_group("Camera Angles")

## Minimum vertical look angle constraint in radians.
@export var min_angle: float = -PI / 6.0

## Maximum vertical look angle constraint in radians.
@export var max_angle: float = PI / 3.0

## Inverts the vertical mouse lookup controls.
@export var invert_vertical: bool = false

@onready var _spring_arm: SpringArm3D = $SpringArm3D

enum RotationMode {
	ALIGN_WITH_CAMERA,   ## Model always faces the same direction as the camera yaw.
	ALIGN_WITH_MOVEMENT  ## Model only rotates when moving, facing the movement direction.
}

@export_group("Character Model Rotation")
## The visual model node to rotate.
@export var character_model: Node3D
## How to orient the character model relative to the camera or movement direction.
@export var rotation_mode: RotationMode = RotationMode.ALIGN_WITH_MOVEMENT
## Speed at which the character model rotates.
@export var model_rotation_speed: float = 10.0

var _camera_input_direction := Vector2.ZERO
var _movement_vector := Vector3.ZERO


func _ready() -> void:
	_spring_arm.spring_length = spring_length


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and 
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity


## Sets the current movement direction vector (in world space) to rotate the model.
func set_movement_vector(vec: Vector3) -> void:
	_movement_vector = vec


func _physics_process(delta: float) -> void:
	# Camera Rotation
	if invert_vertical:
		rotation.x += _camera_input_direction.y * delta
	else:
		rotation.x -= _camera_input_direction.y * delta
		
	rotation.x = clamp(rotation.x, min_angle, max_angle)
	rotation.y -= _camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO

	# Handle character model rotation modes
	if character_model:
		match rotation_mode:
			RotationMode.ALIGN_WITH_CAMERA:
				character_model.rotation.y = rotation.y
			RotationMode.ALIGN_WITH_MOVEMENT:
				var velocity_horizontal = Vector3(_movement_vector.x, 0.0, _movement_vector.z)
				if velocity_horizontal.length_squared() > 0.01:
					var target_angle = atan2(-velocity_horizontal.x, -velocity_horizontal.z)
					character_model.rotation.y = lerp_angle(character_model.rotation.y, target_angle, model_rotation_speed * delta)
