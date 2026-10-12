# Status & Attribute Components

This folder contains components for handling health, regenerative energy/stamina resources, and dynamic, resource-driven attributes.

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

## 3. `AttributesComponent` (`AttributesComponent.gd`)

A data-driven, modular attributes component where stats are defined in a custom Godot `Resource` (such as `examples/ExampleStatus.gd`).

Supports base stat modification and named temporary or permanent additive modifiers (from equipment, spells, status effects, or level-ups).

### Inspector Properties
* `stats_resource: Resource`: The resource defining your character's base stats as `@export var` fields.

### Signals
* `stat_changed(stat_name: String, base_value: float, final_value: float)`

### Methods
* `get_stat(stat_name: String) -> float`: Calculates and returns `base_value + sum_of_active_modifiers`.
* `set_base_stat(stat_name: String, value: float) -> void`: Updates the base stat value and emits `stat_changed`.
* `add_modifier(stat_name: String, modifier_id: String, value: float) -> void`: Adds or overwrites a named modifier and emits `stat_changed`.
* `remove_modifier(stat_name: String, modifier_id: String) -> void`: Removes a named modifier and emits `stat_changed`.

### Setup & Usage Example
1. Define your game's attributes in a custom `Resource` script (e.g., `CharacterStats.gd`):
   ```gdscript
   class_name CharacterStats extends Resource
   
   @export var armor: float = 20.0
   @export var magic_resist: float = 10.0
   @export var speed: float = 200.0
   ```
2. Create an instance of this resource (`.tres`) and assign it to `stats_resource` on `AttributesComponent`.
3. Query or apply modifiers in code:
   ```gdscript
   @onready var attributes: AttributesComponent = $AttributesComponent

   func _ready() -> void:
       # Read total stat
       var total_armor = attributes.get_stat("armor")
       
       # Add an equipment or buff modifier (+15.0 armor from shield)
       attributes.add_modifier("armor", "iron_shield", 15.0)
       
       # Remove modifier when shield is unequipped
       attributes.remove_modifier("armor", "iron_shield")
   ```
