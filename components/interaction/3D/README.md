# 3D Interaction Components

Two complementary components providing raycast-based player interaction in 3D space.

---

## 📄 Scripts

### 1. `Interactor3D` (`Interactor3D.gd`)
A `RayCast3D` attached to the player character or camera pivot, pointing forward.

* **Configuration**:
  * Set `collide_with_areas = true` and `collide_with_bodies = false`.
  * Set `hit_from_inside = true`.
  * Adjust `target_position` (e.g. `Vector3(0, 0, -4)`) to set interaction reach.
* **Signals**:
  * `focused_interactable(node: Node)`: Emitted when the raycast starts pointing at a node in the `"Interactable"` group.
  * `unfocused_interactable(node: Node)`: Emitted when the raycast moves away from the previous interactable.
* **Methods**:
  * `try_interaction(player: Node) -> void`: If pointing at an `Interactable3D`, invokes `request_interaction(player)`.

### 2. `Interactable3D` (`Interactable3D.gd`)
An `Area3D` placed on an interactive world object (e.g. shrine, door, button, loot crate).

* **Signals**:
  * `interacted(player: Node)`: Emitted when triggered by an `Interactor3D`.
* **Methods**:
  * `request_interaction(player: Node) -> void`: Emits `interacted(player)`.

---

## 🧪 Usage Example (from `tests/3d test`)

### On the Interactable Object (`3d test scene.tscn` & `node_3d.gd`)
1. Add an `Interactable3D` (with a `CollisionShape3D`) to your interactive object.
2. Add the `Interactable3D` to group `"Interactable"`.
3. Connect the `interacted` signal to your handler script:
```gdscript
extends Node3D

func _on_interactable_interacted(player: Node) -> void:
	print("Interacted with by: ", player.name)
	queue_free() # Destroys or activates the object
```

### On the Player (`Player3D.tscn` & `character_body_3d.gd`)
1. Attach `Interactor3D` as a child of the player or camera pivot.
2. In your player script:
```gdscript
extends CharacterBody3D

@export var interactor: Interactor3D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interactor.try_interaction(self)
```
