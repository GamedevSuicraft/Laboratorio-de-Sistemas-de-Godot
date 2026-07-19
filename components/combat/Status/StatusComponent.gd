## Manages character attributes that change less frequently, such as Armor, Strength, or Speed.
## Supports temporary or permanent modifiers (e.g. from level trackers, items, or status effects).
##
## To use:
## 1. Create a custom Resource class (e.g. extending Resource) and declare your stats as @export variables.
## 2. Assign an instance of this resource to 'stats_resource' in the inspector.
## 3. Retrieve final stats with get_stat(), which calculates base_value + active_modifiers.
@icon("./icons/status.svg")
class_name StatusComponent extends Node

signal stat_changed(stat_name: String, base_value: float, final_value: float)

## Resource containing the default base stats. Declare your stats as @export variables in this resource.
@export var stats_resource: Resource

## The active base values for all stats, initialized from the stats_resource.
var base_stats: Dictionary = {}

# Stores active modifiers per stat: { stat_name: { modifier_id: value } }
var _modifiers: Dictionary = {}


func _ready() -> void:
	_initialize_base_stats()


## Initializes the base_stats dictionary dynamically from the variables defined in stats_resource.
func _initialize_base_stats() -> void:
	if not stats_resource:
		return
	
	for prop in stats_resource.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var stat_name = prop.name
			base_stats[stat_name] = stats_resource.get(stat_name)


## Returns the final value of a stat, combining its base value and any active modifiers.
func get_stat(stat_name: String) -> float:
	var base = base_stats.get(stat_name, 0.0)
	var mod_sum = 0.0
	if _modifiers.has(stat_name):
		for mod_val in _modifiers[stat_name].values():
			mod_sum += mod_val
	return base + mod_sum


## Updates the base value of a stat (e.g. from level ups).
func set_base_stat(stat_name: String, value: int) -> void:
	base_stats[stat_name] = value
	stat_changed.emit(stat_name, value, get_stat(stat_name))


## Adds or updates a modifier to a stat (e.g. from weapons, armor, status effects).
func add_modifier(stat_name: String, modifier_id: String, value: int) -> void:
	if not _modifiers.has(stat_name):
		_modifiers[stat_name] = {}
	_modifiers[stat_name][modifier_id] = value
	stat_changed.emit(stat_name, base_stats.get(stat_name, 0.0), get_stat(stat_name))


## Removes a modifier from a stat.
func remove_modifier(stat_name: String, modifier_id: String) -> void:
	if _modifiers.has(stat_name) and _modifiers[stat_name].has(modifier_id):
		_modifiers[stat_name].erase(modifier_id)
		if _modifiers[stat_name].is_empty():
			_modifiers.erase(stat_name)
		stat_changed.emit(stat_name, base_stats.get(stat_name, 0.0), get_stat(stat_name))
