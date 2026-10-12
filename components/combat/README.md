# Combat & Attributes Components

A suite of decoupled, resource-driven components for managing character health, resources (mana, stamina), RPG attributes, and ticking status effects.

These components are agnostic to the dimension (they work seamlessly on both 2D and 3D character bodies) and follow composition over inheritance.

---

## 📁 Subfolders

* [`Status/`](Status/README.md):
  * `HealthComponent.gd`: Health management (damage, heal, death).
  * `ResourceComponent.gd`: Dynamic pool (stamina, mana) with auto-regeneration. Used in `tests/3d test/Player3D.tscn`.
  * `AttributesComponent.gd`: Dynamic, data-driven attributes system driven by custom `Resource` definitions with support for additive modifiers.
* [`StatusEffects/`](StatusEffects/README.md):
  * `StatusEffect.gd`: Resource blueprint for defining effects (tick rate, duration).
  * `StatusEffectManager.gd`: Node manager that handles effect lifecycles, ticks, and expiration.

---

## ⚡ Quick Start: Health & Damage

Attach `HealthComponent` as a child node to any character:

```gdscript
extends CharacterBody2D # or CharacterBody3D

@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
    health_component.damaged.connect(_on_damaged)
    health_component.died.connect(_on_died)

func take_hit(amount: float) -> void:
    health_component.damage(amount)

func _on_damaged(amount: float) -> void:
    print("Ouch! Lost %f health. Remaining: %f" % [amount, health_component.current_health])

func _on_died() -> void:
    print("Character died!")
    queue_free()
```

---

## ⚡ Quick Start: Stamina / Mana Resource

In `tests/3d test/sceneScripts/character_body_3d.gd`, `ResourceComponent` is attached as a `Stamina` node to drive sprint stamina consumption:

```gdscript
@export var stamina: ResourceComponent
@export var running_stamina_cost: float = 10.0
@export var sprint_speed: float = 20.0
@export var walk_speed: float = 10.0

func _physics_process(delta: float) -> void:
    # consume_over_time returns true if stamina was successfully drained
    if Input.is_key_pressed(KEY_SHIFT) and stamina.consume_over_time(running_stamina_cost, delta):
        movement.speed = sprint_speed
    else:
        movement.speed = walk_speed
```

---

## ⚡ Quick Start: Status Effects (Damage-over-Time / Buffs)

1. Create a `StatusEffect` resource (such as `tests/2d test/statusEffects/burn.tres`):
   ```ini
   effect_id = "Burn"
   duration = 4.0
   tick_rate = 1.0
   ```
2. Attach `StatusEffectManager` to the target and listen to its signals:
   ```gdscript
   @onready var effects_manager: StatusEffectManager = $StatusEffectManager
   @onready var health: HealthComponent = $HealthComponent

   func _ready() -> void:
       effects_manager.effect_ticked.connect(_on_effect_tick)

   func _on_effect_tick(effect_id: String) -> void:
       match effect_id:
           "Burn":
               health.damage(5.0)
   ```
