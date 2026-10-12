# 3D Button & Pressure Plate System

A physical, animated 3D pressure plate trigger for puzzle mechanics, opening doors, or triggering traps.

---

## 📄 Scripts & Scenes

* `3D/PressurePlate/PressurePlateLogic.gd` (`Area3D`): Manages body detection, tweening of the button mesh, and signal dispatching.
* **Test Scene Reference**: [`tests/3d test/Button.tscn`](../../tests/3d%20test/Button.tscn) and [`tests/3d test/sceneScripts/buttonController.gd`](../../tests/3d%20test/sceneScripts/buttonController.gd).

---

## ⚙️ Inspector Properties

* `target_node: Node3D`: Reference to the visual or physics node to depress/move (e.g. an `AnimatableBody3D` or `MeshInstance3D`).
* `move_offset: Vector3 = Vector3(0, -0.2, 0)`: Direction and distance the plate depresses when pressed.
* `duration: float = 0.15`: Duration of the press and release tween animations in seconds.

---

## 📡 Signals

* `pressed`: Emitted when the first body enters the trigger area.
* `released`: Emitted when all bodies have exited the trigger area.

---

## 🧪 Usage Example (from `tests/3d test`)

### 1. Scene Setup
Create a plate assembly scene (see [`tests/3d test/Button.tscn`](../../tests/3d%20test/Button.tscn)):
```
Button (Node3D)
├── RigidBody3D / AnimatableBody3D (The moving plate mesh)
│   ├── CollisionShape3D
│   └── MeshInstance3D
└── Area3D (PressurePlateLogic.gd)
    └── CollisionShape3D
```
* Assign `RigidBody3D` to the `target_node` property of `PressurePlateLogic`.

### 2. Connect Signals in Controller Script
```gdscript
extends Node3D

func _on_area_3d_pressed() -> void:
    print("Pressure plate activated!")
    # e.g., open door, trigger elevator, play sound

func _on_area_3d_released() -> void:
    print("Pressure plate deactivated!")
    # e.g., close door
```
