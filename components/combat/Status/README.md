# Status & Attribute Components

This folder contains components for handling health, regenerative energy/stamina resources, combat defense stats, and resource-driven attributes.

---

## 1. `HealthComponent` (`HealthComponent.gd`)

Manages the health pool, healing, and damage reception for any actor.

### Properties
* `max_health: float`: Maximum health (clamped to >= 1.0).
* `current_health: float`: Current health value (clamped between 0 and `max_health`).

### Signals
* `health_changed(current: float, max_health: float)`
* `damaged(amount: float)`
* `healed(amount: float)`
* `died()`

### Methods
* `damage(amount: float) -> void`: Reduces health and emits `damaged`. If health reaches 0, emits `died`.
* `heal(amount: float) -> void`: Increases health up to `max_health` and emits `healed`.

### Usage Example
```gdscript
@onready var health: HealthComponent = $HealthComponent

func take_damage(dmg: float) -> void:
    health.damage(dmg)
```

---

## 2. `ResourceComponent` (`ResourceComponent.gd`)

Handles frequently fluctuating resources such as Stamina, Mana, or Shield Energy. Supports automatic regeneration and consumption over time or instantly.

> **Test Scene Reference**: Used as the `Stamina` node in [`tests/3d test/Player3D.tscn`](../../tests/3d%20test/Player3D.tscn) and consumed in [`tests/3d test/sceneScripts/character_body_3d.gd`](../../tests/3d%20test/sceneScripts/character_body_3d.gd).

### Properties
* `resource_name: String`: Name identifier (e.g. `"Stamina"`).
* `max_value: float`: Maximum capacity.
* `current_value: float`: Current amount available.
* `regen_rate: float`: Amount restored per second. Set to `0.0` to disable auto-regeneration.
* `regen_cooldown: float`: Delay in seconds after consumption before regeneration begins.

### Signals
* `resource_changed(current: float, max_value: float)`
* `resource_empty()`
* `resource_full()`

### Methods
* `consume(amount: float) -> bool`: Instantly deducts an amount (e.g., spell cast, jump). Returns `true` if sufficient resource was available.
* `consume_over_time(rate: float, delta: float) -> bool`: Consumes continuously (e.g., sprinting). Returns `false` once depleted.
* `gain(amount: float) -> void`: Adds resource up to `max_value`.

### Usage Example (Sprinting from 3D Test Scene)
```gdscript
@export var stamina: ResourceComponent
@export var running_stamina_cost: float = 10.0

func _physics_process(delta: float) -> void:
    if Input.is_key_pressed(KEY_SHIFT) and stamina.consume_over_time(running_stamina_cost, delta):
        speed = 20.0
    else:
        speed = 10.0
```

---

## 3. `StatsComponent` (`StatsComponent.gd`)

Stores base RPG combat stats (`armor`, `magic_resist`, `penetration`) and calculates dynamic modifier bonuses.

### Methods
* `add_modifier(stat_name: StringName, id: String, value: float) -> void`: Adds or overwrites a named modifier.
* `remove_modifier(stat_name: StringName, id: String) -> void`: Removes a specific modifier by ID.
* `get_modified_value(stat_name: StringName) -> float`: Returns `base_value + sum_of_modifiers`.

### Usage Example
```gdscript
stats.add_modifier(&"armor", "iron_shield", 15.0)
var effective_armor = stats.get_modified_value(&"armor")
```

---

## 4. `StatusComponent` (`StatusComponent.gd`)

A data-driven attribute component where stats are defined in a custom Godot `Resource` (such as `examples/ExampleStatus.gd`).

### Setup
1. Create a script extending `Resource`:
   ```gdscript
   class_name CharacterStatsResource extends Resource
   @export var strength: int = 10
   @export var agility: int = 8
   ```
2. Assign the `.tres` file to `stats_resource` on `StatusComponent`.
3. Read or modify values dynamically:
   ```gdscript
   status_component.add_modifier("strength", "buff_spell", 5)
   var total_strength = status_component.get_stat("strength") # 15
   ```
