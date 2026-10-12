# Status Effects System

A data-driven status effect system for Godot 4.x, allowing easy implementation of buffs, debuffs, damage-over-time (poison, burn), and regeneration.

---

## 📄 Core Files

1. `StatusEffect.gd` (`Resource`): The template for effect metadata.
2. `StatusEffectManager.gd` (`Node`): The runtime node that tracks timers, triggers ticks, and removes expired effects.
3. `StatusEffectManager.tscn`: A ready-to-use scene containing the node.

---

## ⚙️ Properties & Signals

### `StatusEffect` (`Resource`)
* `effect_id: String`: Unique ID identifying the effect (e.g. `"Burn"`, `"Poison"`, `"Haste"`).
* `duration: float`: Total lifetime of the effect in seconds.
* `tick_rate: float`: Time interval between periodic tick triggers.

### `StatusEffectManager` (`Node`)
* **Methods**:
  * `add_effect(effect: StatusEffect) -> void`: Adds an active effect to the manager.
* **Signals**:
  * `effect_applied(effect_id: String)`: Emitted when an effect is first attached.
  * `effect_ticked(effect_id: String)`: Emitted every `tick_rate` seconds while active.
  * `effect_expired(effect_id: String)`: Emitted when duration elapses.

---

## 🛠️ How to Use (Step-by-Step)

### 1. Create a Status Effect Resource
Create a new resource extending `StatusEffect` (or check the test resource [`tests/2d test/statusEffects/burn.tres`](../../../tests/2d%20test/statusEffects/burn.tres)):
* `effect_id`: `"Burn"`
* `duration`: `4.0`
* `tick_rate`: `1.0`

### 2. Attach `StatusEffectManager` to your Actor
Add `StatusEffectManager` as a child node in your Character scene.

### 3. Connect to Signals in Parent Script
```gdscript
extends CharacterBody2D

@onready var effects_manager: StatusEffectManager = $StatusEffectManager
@onready var health: HealthComponent = $HealthComponent

func _ready() -> void:
    effects_manager.effect_applied.connect(_on_effect_applied)
    effects_manager.effect_ticked.connect(_on_effect_tick)
    effects_manager.effect_expired.connect(_on_effect_expired)

func apply_burn_effect(burn_resource: StatusEffect) -> void:
    effects_manager.add_effect(burn_resource)

func _on_effect_applied(effect_id: String) -> void:
    print("Applied: ", effect_id)

func _on_effect_tick(effect_id: String) -> void:
    match effect_id:
        "Burn":
            health.damage(5.0)

func _on_effect_expired(effect_id: String) -> void:
    print("Expired: ", effect_id)
```
