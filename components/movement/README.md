# Movement Components (2D & 3D)

A set of reusable, kinematic movement components that handle velocity calculation, gravity, and responsive platformer game-feel (Coyote Time & Jump Buffering).

By delegating physics calculations to these components, character scripts remain lightweight and focused strictly on input translation and state coordination.

---

## 📁 Subfolders

* [`2D/`](2D/README.md):
  * `Platformer2DComponent.gd`: 2D horizontal movement, gravity, coyote time, and buffered jumping. (Used in [`tests/2d test/player.tscn`](../../tests/2d%20test/player.tscn)).
  * `TopDown2DComponent.gd`: 2D multi-directional top-down movement controller.
* [`3D/`](3D/README.md):
  * `VelocityComponent3D.gd`: 3D directional movement, gravity, camera-relative orientation, and buffered jumping. (Used in [`tests/3d test/Player3D.tscn`](../../tests/3d%20test/Player3D.tscn)).

---

## 🎮 Game-Feel Features (Platformer)

Both the 2D platformer and 3D velocity components include built-in game-feel parameters:
* **Coyote Time (`coyote_time`)**: Grace period (default `0.15s`) after walking off a ledge where the player can still jump.
* **Jump Buffering (`jump_buffer_time`)**: Window of time (default `0.15s`) before touching the ground where a jump press is remembered and executed automatically upon landing.
