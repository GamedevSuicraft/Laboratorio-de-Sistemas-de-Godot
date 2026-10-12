# Spawner Systems (2D & 3D)

Modular entity and hazard spawners supporting periodic timer-based spawning or manual on-demand triggers. Both systems calculate uniform random spawn positions inside standard Godot collision geometry shapes.

---

## 1. `Spawner2D` (`2D/Spawner2D.gd`)

An `Area2D` that instantiates 2D scenes within the boundary of an assigned collision shape.

### Supported Shapes (`spawn_shape`)
* `RectangleShape2D`: Generates points uniformly across width and height.
* `CircleShape2D`: Generates points uniformly across circular area with square-root radial distribution.
* `CollisionPolygon2D`: Uses rejection sampling over polygon points to generate positions within complex concave/convex polygons.

### Inspector Properties
* `scene_to_spawn: PackedScene`: The enemy, coin, or obstacle scene to instantiate.
* `max_units: int = 5`: Maximum concurrent living units tracked by this spawner. Dead/freed instances are automatically filtered out.
* `respawn_time: float = 5.0`: Interval between spawns. If set to `0.0`, periodic auto-spawning is disabled.
* `spawn_shape: Node2D`: Reference to the `CollisionShape2D` or `CollisionPolygon2D` child.

### Signals & Methods
* `spawned(instance: Node)`: Emitted whenever an entity is created.
* `spawn() -> Node`: Instantiates an entity immediately if `_spawned_units.size() < max_units`.

### Setup
```
Spawner2D (Spawner2D.tscn / Area2D) -> Assign spawn_shape to CollisionShape2D
└── CollisionShape2D (RectangleShape2D / CircleShape2D)
```

---

## 2. `Spawner3D` (`3D/Spawner3D.gd`)

An `Area3D` that instantiates 3D scenes within standard Godot 3D collision volumes.

### Supported Shapes (`spawn_shape`)
* `BoxShape3D`: Generates positions inside volume `[-size/2, size/2]`.
* `SphereShape3D`: Generates uniform points inside sphere radius with cube-root radial distribution.
* `CylinderShape3D`: Generates points within cylinder radius and height.

### Inspector Properties
* `scene_to_spawn: PackedScene`: The 3D scene to instantiate.
* `max_units: int = 5`: Maximum active instances alive at once.
* `respawn_time: float = 5.0`: Spawn timer interval in seconds.
* `spawn_shape: CollisionShape3D`: Reference to the `CollisionShape3D` defining the area.

### Signals & Methods
* `spawned(instance: Node)`: Emitted when an entity is spawned.
* `spawn() -> Node`: Spawns a unit immediately on-demand.

### Setup
```
Spawner3D (Spawner3D.tscn / Area3D) -> Assign spawn_shape to CollisionShape3D
└── CollisionShape3D (BoxShape3D / SphereShape3D / CylinderShape3D)
```
