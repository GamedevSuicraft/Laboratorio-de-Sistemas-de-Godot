# Camera Systems (2D & 3D)

Production-ready camera controllers for 2D platformers and 3D third-person perspectives.

---

## 1. 2D Platformer Camera Smoothing (`SmoothCamera`)

`systems/Camera/2D/PlatformerCameraSmoothing/SmoothCamera.gd` (`Camera2D`)

A specialized 2D platformer camera that features deadzone tracking, speed-based look-ahead lead, and visual debugging gizmos.

> **Test Scene Reference**: Used in [`tests/2d test/TestScene.tscn`](../../tests/2d%20test/TestScene.tscn) tracking the player.

### Inspector Properties
* `target: Node2D`: The node to track (usually a `CharacterBody2D`).
* `lerp_speed: float = 4.0`: How quickly the camera tracks towards the target position.
* `deadzone_size: Vector2 = Vector2(20, 15)`: Rectangular half-extents where minor player movements do not move the camera.
* `look_ahead_amount: float = 30.0`: Distance the camera offsets forward in the direction of movement.
* `look_ahead_y_ratio: float = 0.2`: Vertical multiplier for look-ahead.
* `offset_smoothing: float = 1.5`: Speed of transitioning into look-ahead offsets.
* `horizontal_threshold: float = 10.0`: Speed threshold to activate horizontal look-ahead.
* `vertical_threshold: float = 50.0`: Speed threshold to activate vertical look-ahead.
* `show_debug_visuals: bool = false`: Renders debug boxes for the deadzone and lookahead target on screen.

### Usage Example
Instance `SmoothCamera.tscn` into your 2D scene and assign `target = NodePath("../Player")`:
```gdscript
# In your scene tree:
# TestScene (Node2D)
# ├── Player (CharacterBody2D)
# └── SmoothCamera (Camera2D) -> target = NodePath("../Player")
```

---

## 2. 3D Third-Person Camera (`ThirdPersonCamera`)

`systems/Camera/3D/ThirdPersonCamera/ThirdPersonCamera.gd` (`Node3D`)

An orbital third-person camera using a `SpringArm3D` to prevent clipping into walls and obstacles. Automatically captures and frees mouse control and rotates player character meshes.

> **Test Scene Reference**: Used in [`tests/3d test/Player3D.tscn`](../../tests/3d%20test/Player3D.tscn) and updated via [`tests/3d test/sceneScripts/character_body_3d.gd`](../../tests/3d%20test/sceneScripts/character_body_3d.gd).

### Inspector Properties
* `mouse_sensitivity: float = 0.25`: Mouse look sensitivity.
* `spring_length: float = 8.0`: Distance of the camera behind the player.
* `min_angle: float = -PI / 6.0`: Minimum vertical pitch angle constraint.
* `max_angle: float = PI / 3.0`: Maximum vertical pitch angle constraint.
* `invert_vertical: bool = false`: Inverts pitch rotation.
* `character_model: Node3D`: Visual model node to rotate.
* `rotation_mode: RotationMode`:
  * `ALIGN_WITH_CAMERA`: Mesh faces the camera yaw.
  * `ALIGN_WITH_MOVEMENT`: Mesh smoothly turns towards current velocity direction.
* `model_rotation_speed: float = 10.0`: Interpolation speed for model orientation.

### Controls
* `left_click`: Captures mouse (`MOUSE_MODE_CAPTURED`).
* `ui_cancel` (Escape): Releases mouse (`MOUSE_MODE_VISIBLE`).

### Usage Example (from `tests/3d test`)
Attach `ThirdPersonCamera.tscn` to the player body and feed horizontal velocity to it in `_physics_process`:
```gdscript
extends CharacterBody3D

@export var camera_pivot: ThirdPersonCamera

func _physics_process(_delta: float) -> void:
    # After moving:
    if camera_pivot and camera_pivot.has_method("set_movement_vector"):
        camera_pivot.set_movement_vector(velocity)
```
