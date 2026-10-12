# 2D Interaction Components

Two complementary components providing raycast-based player interaction in 2D space.

---

## 📄 Scripts

### 1. `Interactor2D` (`Interactor2D.gd`)
A `RayCast2D` attached to the player character pointing in the facing direction.

* **Configuration**:
  * Set `collide_with_areas = true` and `collide_with_bodies = false` (or `true` if needed).
  * Set `hit_from_inside = true`.
  * Adjust `target_position` to set the interaction reach distance.
* **Signals**:
  * `focused_interactable(node: Node)`: Emitted when the raycast starts hitting a node in the `"Interactable"` group.
  * `unfocused_interactable(node: Node)`: Emitted when the raycast stops hitting the previous interactable.
* **Methods**:
  * `try_interaction(player: Node) -> void`: If pointing at an `Interactable2D`, triggers `request_interaction(player)`.

### 2. `Interactable2D` (`Interactable2D.gd`)
An `Area2D` placed on an interactive world object (e.g. chest, door, lever).

* **Signals**:
  * `interacted(player: Node)`: Emitted when an interaction is triggered, passing the interacting player instance.
* **Methods**:
  * `request_interaction(player: Node) -> void`: Emits `interacted(player)`.

---

## 🧪 Usage Example (from `tests/2d test`)

### On the Interactable Object (e.g., Chest: `chest.tscn` & `chest.gd`)
1. Create a root `Node2D` with an `Interactable2D` child (which has a `CollisionShape2D`).
2. Add the `Interactable2D` to group `"Interactable"`.
3. Connect the `interacted` signal of `Interactable2D` to your script:
```gdscript
extends Node2D

func _on_interactable_interacted(player: Node) -> void:
    print("The chest was opened by: ", player.name)
```

### On the Player (`player.tscn` & `playerController.gd`)
1. Attach `Interactor2D` as a child node of `CharacterBody2D`.
2. Connect input handling:
```gdscript
extends CharacterBody2D

@export var interactor: Interactor2D

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        interactor.try_interaction(self)
```
