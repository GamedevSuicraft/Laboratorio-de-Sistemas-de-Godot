## Handles frequently changing resources, such as Mana, Stamina, or Energy.
##
## To use:
## 1. Add this component as a child of a character (rename it to e.g. "ManaComponent" or "StaminaComponent").
## 2. Configure maximum capacity, initial value, and regeneration rate in the inspector.
## 3. Call consume() when performing actions, and listen to 'resource_changed' or 'resource_empty'.
@icon("./icons/resource.svg")
class_name ResourceComponent extends Node

signal resource_changed(current: float, max_value: float)
signal resource_empty
signal resource_full

## The identifier/name of the resource (e.g., Stamina, Mana, Energy).
@export var resource_name: String = "Stamina"

## The maximum capacity limit for the resource.
@export var max_value: float = 100.0:
	set(val):
		max_value = max(val, 1.0)
		current_value = clamp(current_value, 0.0, max_value)
		resource_changed.emit(current_value, max_value)

## The current quantity of the resource.
@export var current_value: float = 100.0:
	set(val):
		current_value = clamp(val, 0.0, max_value)
		resource_changed.emit(current_value, max_value)

## Regeneration amount added per second. Set to 0.0 to disable auto-regeneration.
@export var regen_rate: float = 0.0

## Cooldown time (in seconds) to wait before regeneration starts after consumption. Set to 0.0 for instant regeneration.
@export var regen_cooldown: float = 1.0

@export var debug := false

var _regen_timer: float = 0.0


func _ready() -> void:
	# Ensure initial value is within boundaries
	current_value = clamp(current_value, 0.0, max_value)


func _process(delta: float) -> void:
	if debug:
		print("[ResourceComponent-%s]: %f" % [name, current_value])
	
	if _regen_timer > 0.0:
		_regen_timer -= delta
	elif regen_rate > 0.0 and current_value < max_value:
		gain(regen_rate * delta)


## Consumes the specified amount of resource instantly (e.g. casting a spell, jump). 
## Returns true if successful (full amount is available), false otherwise.
func consume(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if current_value >= amount:
		current_value -= amount
		_regen_timer = regen_cooldown
		if current_value <= 0.0:
			resource_empty.emit()
		return true
	return false


## Consumes the resource over time (e.g. running, holding shield). Uses delta.
## If the current value is less than the required tick amount, it consumes the remainder, 
## drains the resource to 0.0, triggers 'resource_empty', and returns true.
func consume_over_time(rate: float, delta: float) -> bool:
	var amount = rate * delta
	if amount <= 0.0:
		return true
	if current_value <= 0.0:
		return false
	
	if current_value >= amount:
		current_value -= amount
		_regen_timer = regen_cooldown
		if current_value <= 0.0:
			resource_empty.emit()
		return true
	else:
		current_value = 0.0
		_regen_timer = regen_cooldown
		resource_empty.emit()
		return true


## Adds the specified amount to the resource, capped at max_value.
func gain(amount: float) -> void:
	if amount <= 0.0:
		return
	
	var old_value = current_value
	current_value += amount
	
	if current_value >= max_value and old_value < max_value:
		resource_full.emit()
