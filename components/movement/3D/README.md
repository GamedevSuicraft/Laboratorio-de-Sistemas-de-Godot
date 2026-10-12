# 3D Movement Components

Kinematic movement components for 3D `CharacterBody3D` nodes.

---

## 1. `VelocityComponent3D` (`Platformer/VelocityComponent3D.gd`)

Handles horizontal 3D movement, gravity, jumping, coyote time, jump buffering, and camera-relative orientation.

> **Test Scene Reference**: Used in [`tests/3d test/Player3D.tscn`](../../../tests/3d%20test/Player3D.tscn) and executed in [`tests/3d test/sceneScripts/character_body_3d.gd`](../../../tests/3d%20test/sceneScripts/character_body_3d.gd).

### Inspector Properties
* `speed: float = 10.0`: Movement speed in units per second. Can be adjusted dynamically for walking vs sprinting.
* `jump_velocity: float = 5.0`: Vertical velocity impulse applied on jumping.
* `gravity_multiplier: float = 1.0`: Multiplier for `ProjectSettings.get_setting("physics/3d/default_gravity")`.
* `movement_reference: Node3D`: Reference pivot (typically the `ThirdPersonCamera` or player head) used to orient input vectors in world space.
* `coyote_time: float = 0.15`: Window in seconds to jump after slipping off an edge.
* `jump_buffer_time: float = 0.15`: Window in seconds to buffer a jump press before landing.

### Method
```gdscript
func move_and_jump(body: CharacterBody3D, input_vector: Vector3, jump_pressed: bool, delta: float) -> void
```

### Usage Example (from `tests/3d test`)
```gdscript
extends CharacterBody3D

@export var movement: VelocityComponent3D
@export var camera_pivot: ThirdPersonCamera
@export var walk_speed: float = 10.0

func _physics_process(delta: float) -> void:
    var jump_pressed = Input.is_action_just_pressed("ui_accept")
    
    # Input vector (X: horizontal, Z: forward/back)
    var direction = Vector3(
        Input.get_axis("ui_left", "ui_right"),
        1.0,
        Input.get_axis("ui_up", "ui_down")
    )
    
    movement.move_and_jump(self, direction, jump_pressed, delta)
    
    # Update camera model rotation
    if camera_pivot and camera_pivot.has_method("set_movement_vector"):
        camera_pivot.set_movement_vector(velocity)
```
