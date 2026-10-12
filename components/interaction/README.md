# Interaction Components (2D & 3D)

A clean, decoupled interaction system supporting both 2D and 3D games in Godot 4.

The architecture divides the interaction into two distinct roles:
1. **`Interactor`** (`RayCast2D` / `RayCast3D`): Owned by the player or agent. Casts a ray forwards to detect interactable objects in sight/reach and triggers interaction when the player presses an action key.
2. **`Interactable`** (`Area2D` / `Area3D`): Placed on the interactive world object (chests, switches, NPCs, doors). Receives the interaction request and emits an `interacted(player)` signal to execute custom object logic.

---

## 📁 Subfolders

* [`2D/`](2D/README.md):
  * `Interactable2D.gd`: `Area2D` subclass placed on 2D world objects.
  * `Interactor2D.gd`: `RayCast2D` subclass attached to the player.
  * **Test Reference**: Tested in [`tests/2d test/TestScene.tscn`](../../tests/2d%20test/TestScene.tscn) with chest [`tests/2d test/chest.tscn`](../../tests/2d%20test/chest.tscn).
* [`3D/`](3D/README.md):
  * `Interactable3D.gd`: `Area3D` subclass placed on 3D world objects.
  * `Interactor3D.gd`: `RayCast3D` subclass attached to the player/camera.
  * **Test Reference**: Tested in [`tests/3d test/3d test scene.tscn`](../../tests/3d%20test/3d%20test%20scene.tscn) with player [`tests/3d test/Player3D.tscn`](../../tests/3d%20test/Player3D.tscn).

---

## 🎯 Design Highlights

* **Zero Coupling**: The player script does not need to know what kind of object it is facing (door, NPC, chest). It simply calls `interactor.try_interaction(self)`.
* **Signal-Driven**: The interactable object emits `interacted(player)` so you can connect the response via the Godot editor or script.
* **UI Focus Prompts**: Both interactors emit `focused_interactable` and `unfocused_interactable` signals, making it trivial to display UI prompts (e.g. "[E] Open Chest").
