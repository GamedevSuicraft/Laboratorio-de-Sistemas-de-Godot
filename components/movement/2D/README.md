# 2D Movement Components

Modular movement components for 2D `CharacterBody2D` nodes.

---

## 1. `Platformer2DComponent` (`Platformer/Platformer2DComponent.gd`)

Handles horizontal running, gravity calculation, jump execution, coyote time, and jump buffering.

> **Test Scene Reference**: Used in [`tests/2d test/player.tscn`](../../../tests/2d%20test/player.tscn) and executed in [`tests/2d test/playerController.gd`](../../../tests/2d%20test/playerController.gd).

### Inspector Properties
* `speed: float = 200.0`: Horizontal velocity in pixels per second.
* `jump_velocity: float = 1000.0`: Upward impulse velocity when jumping.
* `gravity_multiplier: float = 1.0`: Multiplier for `ProjectSettings.get_setting("physics/2d/default_gravity")`.
* `coyote_time: float = 0.15`: Window in seconds to jump after slipping off a ledge.
* `jump_buffer_time: float = 0.15`: Window in seconds to buffer a jump press before landing.

### Method
```gdscript
func move_and_jump(body: CharacterBody2D, direction_x: float, jump_pressed: bool, delta: float) -> void
```

### Usage Example (from `tests/2d test`)
```gdscript
extends CharacterBody2D

@export var movement: Platformer2DComponent

func _physics_process(delta: float) -> void:
    var direction_x = Input.get_axis("ui_left", "ui_right")
    var jump_pressed = Input.is_action_just_pressed("ui_accept")
    movement.move_and_jump(self, direction_x, jump_pressed, delta)
```

---

## 2. `TopDown2DComponent` (`TopDown/TopDown2DComponent.gd`)

Handles multi-directional 8-way or analog 2D movement for top-down games, RPGs, or twin-stick shooters.

### Inspector Properties
* `speed: float = 200.0`: Movement speed in pixels per second.

### Method
```gdscript
func move(body: CharacterBody2D, direction: Vector2) -> void
```

### Usage Example
```gdscript
extends CharacterBody2D

@export var movement: TopDown2DComponent

func _physics_process(_delta: float) -> void:
    var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    movement.move(self, input_vector)
```
