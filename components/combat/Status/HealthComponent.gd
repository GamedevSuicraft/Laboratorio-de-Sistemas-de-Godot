## Handles character health, taking damage, healing, and death.
##
## To use:
## 1. Add this component as a child of a character (CharacterBody2D/3D or Area2D/3D).
## 2. Connect to signals like 'died' or 'health_changed' to trigger animations, UI updates, or character removal.
## 3. Hitboxes or projectiles can call damage() on this component to apply damage.
@icon("./icons/health.svg")
class_name HealthComponent extends Node

signal health_changed(current: float, max_health: float)
signal damaged(amount: float)
signal healed(amount: float)
signal died

## The maximum health of the character.
@export var max_health: float = 100.0:
	set(val):
		max_health = max(val, 1.0)
		current_health = clamp(current_health, 0.0, max_health)
		health_changed.emit(current_health, max_health)

## The current health of the character.
@export var current_health: float = 100.0:
	set(val):
		current_health = clamp(val, 0.0, max_health)
		health_changed.emit(current_health, max_health)


func _ready() -> void:
	# Ensure initial current health is clamped to max health
	current_health = clamp(current_health, 0.0, max_health)


## Applies damage to the health pool. Emits 'damaged' and 'died' if health reaches zero.
func damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	
	current_health -= amount
	damaged.emit(amount)
	
	if current_health <= 0.0:
		died.emit()


## Restores health to the health pool, up to max_health.
func heal(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	
	current_health += amount
	healed.emit(amount)
