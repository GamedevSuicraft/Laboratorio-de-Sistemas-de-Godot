# Godot Modular Systems Library

A modular, decoupled library of game development components and systems for **Godot Engine 4.x** (GDScript 2).

---

## 🎯 Main Purpose

The core goal of this repository is to **develop modular gamedev components for Godot to improve game dev prototyping and real projects speed**.

Whether building a game in a 48-hour game jam or architecting a large-scale commercial game, developers often rewrite the same foundational logic: movement controllers, health pools, interaction raycasts, inventory stacks, cameras, and spawner logic. 

This library solves that by providing plug-and-play, single-responsibility nodes and resources that:
* **Accelerate Prototyping**: Drop components into character bodies or scenes and get fully functional mechanics in minutes without writing boilerplate.
* **Scale to Production**: Built with strict software engineering practices—clean code, strong static typing, zero circular dependencies, and complete separation between data (`Resource`), logic (`Node`), and visuals.

---

## 🏛️ Architectural Principles

The library is built following strict Godot 4 architectural standards:

1. **Composition over Inheritance**: Game entities (`CharacterBody2D`, `CharacterBody3D`, interactables) are assembled by attaching specialized component nodes rather than building deep class inheritance trees.
2. **Unidirectional SceneTree Communication**:
   * **Downward (Parent to Child)**: Parents hold direct references (`@export` or `@onready`) to their component children and invoke their methods.
   * **Upward (Child to Parent)**: Children communicate strictly via **Signals** (e.g., `health_changed`, `died`, `interacted`, `inventory_changed`). Components never call `get_parent()` or make assumptions about the node hierarchy above them.
3. **Data-Driven Logic via Resources**: Configuration, items, and status effects use Godot `Resource` types (`.tres`), enabling designers to create and adjust game data directly from the Inspector.
4. **Clean 2D & 3D Separation**: 2D and 3D implementations share design paradigms and abstractions while keeping their respective physics and spatial APIs cleanly isolated.

---

## 📂 Repository Structure

```
├── components/          # Pluggable entity-level logic (attached to actors/objects)
│   ├── combat/          # Health, stamina/mana resources, stats, status effects
│   ├── interaction/     # Raycast interactors & interactable area triggers (2D & 3D)
│   ├── inventory/       # Stackable slot-based inventory and item resources
│   └── movement/        # Kinematic controllers with game-feel buffering (2D & 3D)
├── systems/             # Standalone environmental and world-level systems
│   ├── Button/          # Physical 3D interactive pressure plates & triggers
│   ├── Camera/          # 2D deadzone/lookahead camera & 3D third-person spring arm
│   ├── Spawner/         # Area-based periodic/on-demand entity spawners (2D & 3D)
│   └── TimeController/  # Day/night 24-hour cycle clock system
├── tests/               # Integrated test sandboxes demonstrating usage
│   ├── 2d test/         # 2D platformer sandbox (movement, camera, inventory, chest)
│   └── 3d test/         # 3D third-person sandbox (movement, stamina, interaction, button)
└── autoloads/           # Self-contained global singletons (e.g., AudioManager)
```

---

## 🧩 Components Overview

| Component | Type | Description | Reference Test |
| :--- | :--- | :--- | :--- |
| [`HealthComponent`](components/combat/Status/README.md) | `Node` | Manages HP, taking damage, healing, and death signals. | Unused in tests (documented) |
| [`ResourceComponent`](components/combat/Status/README.md) | `Node` | Dynamic resource pool (Stamina, Mana, Energy) with auto-regen & cooldowns. | `tests/3d test/Player3D.tscn` |
| [`AttributesComponent`](components/combat/Status/README.md#3-attributescomponent-attributescomponentgd) | `Node` | Dynamic attribute system driven by custom `Resource` definitions with modifier calculations. | Combat & RPG systems |
| [`StatusEffectManager`](components/combat/StatusEffects/README.md) | `Node` | Ticks and expires timed effects defined by [`StatusEffect`](components/combat/StatusEffects/README.md) resources. | `tests/2d test/statusEffects/burn.tres` |
| [`Interactable2D`](components/interaction/2D/README.md) | `Area2D` | Marks a 2D object as interactable and emits `interacted(player)`. | `tests/2d test/chest.tscn` |
| [`Interactor2D`](components/interaction/2D/README.md) | `RayCast2D` | Player raycast detecting interactables and triggering interaction on key press. | `tests/2d test/player.tscn` |
| [`Interactable3D`](components/interaction/3D/README.md) | `Area3D` | Marks a 3D object as interactable and emits `interacted(player)`. | `tests/3d test/3d test scene.tscn` |
| [`Interactor3D`](components/interaction/3D/README.md) | `RayCast3D` | Player raycast detecting interactables in front of the camera/character. | `tests/3d test/Player3D.tscn` |
| [`InventoryComponent`](components/inventory/README.md) | `Node` | Slot-based inventory handling stack limits, adding, and removing items. | `tests/2d test/player.tscn` |
| [`Platformer2DComponent`](components/movement/2D/README.md) | `Node` | 2D side-scrolling movement with Coyote Time and Jump Buffering. | `tests/2d test/player.tscn` |
| [`TopDown2DComponent`](components/movement/2D/README.md) | `Node` | 2D multi-directional top-down movement controller. | 2D TopDown games |
| [`VelocityComponent3D`](components/movement/3D/README.md) | `Node` | 3D movement and jumping relative to camera direction with jump buffering. | `tests/3d test/Player3D.tscn` |

---

## ⚙️ Systems Overview

| System | Type | Description | Reference Test |
| :--- | :--- | :--- | :--- |
| [`PressurePlateLogic`](systems/Button/README.md) | `Area3D` | Physical button that animates via Tween when stepped on by bodies. | `tests/3d test/Button.tscn` |
| [`SmoothCamera`](systems/Camera/README.md#2d-platformer-camera-smoothing) | `Camera2D` | Platformer camera with deadzone boxes, speed look-ahead, and debug drawings. | `tests/2d test/TestScene.tscn` |
| [`ThirdPersonCamera`](systems/Camera/README.md#3d-third-person-camera) | `Node3D` | SpringArm3D orbit camera with mouse capture, pitch clamps, and model alignment. | `tests/3d test/Player3D.tscn` |
| [`Spawner2D`](systems/Spawner/README.md#spawner2d) | `Area2D` | Spawns packed scenes inside rectangles, circles, or custom 2D collision polygons. | Spawner 2D system |
| [`Spawner3D`](systems/Spawner/README.md#spawner3d) | `Area3D` | Spawns packed scenes inside boxes, spheres, or cylinder 3D collision shapes. | Spawner 3D system |
| [`TimeController`](systems/TimeController/README.md) | `Node` | 24-hour day/night cycle manager emitting normalized progress and clock hours. | Time system |

---

## 🧪 Testing and Sandboxes

The project includes functional test environments to see all components wired together in real Godot scenes:

* **2D Test Sandbox (`res://tests/2d test/TestScene.tscn`)**:
  * Character body driven by `Platformer2DComponent` and `SmoothCamera`.
  * Interaction test using `Interactor2D` and a chest (`chest.tscn`) using `Interactable2D`.
  * Pre-populated inventory using `InventoryComponent` and `SwordItem.tres`.
* **3D Test Sandbox (`res://tests/3d test/3d test scene.tscn`)**:
  * Character body driven by `VelocityComponent3D`, `ThirdPersonCamera`, and `ResourceComponent` (Stamina for sprinting).
  * Raycast interaction via `Interactor3D` and interactable pillar using `Interactable3D`.
  * Interactive pressure plate using `PressurePlateLogic` in `Button.tscn`.
  * Shader visualizers (dissolve shader, screen effects).

---

## 🚀 Quick Usage Example

Here is how simple it is to build a responsive 2D platformer character using composition:

```gdscript
extends CharacterBody2D

@export var movement: Platformer2DComponent
@export var interactor: Interactor2D
@export var inventory: InventoryComponent

func _physics_process(delta: float) -> void:
    var direction_x = Input.get_axis("ui_left", "ui_right")
    var jump_pressed = Input.is_action_just_pressed("ui_accept")
    
    # Delegate movement calculation and physics execution to the component
    movement.move_and_jump(self, direction_x, jump_pressed, delta)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        interactor.try_interaction(self)
```

For detailed guides, API references, and sample scenes for any component or system, refer to their respective folder `README.md` files.
