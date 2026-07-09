@icon("./stats.svg")
class_name StatsManager extends Node

signal stat_changed(stat_name: String, current_value: int)
signal stat_full(stat_name: String)
signal stat_empty(stat_name: String)

enum PersistencePolicy {
	ALWAYS_FULL,  
	PERSIST_STATE
}

@export var persistence_policy: PersistencePolicy = PersistencePolicy.ALWAYS_FULL
@export var stats: StatsData
@export var current: StatsData

var limits: Dictionary = {}
var current_values: Dictionary = {}

var is_limits_dirty: bool = false
var is_current_dirty: bool = false


func _ready() -> void:
	if not stats:
		push_error("StatManager needs a StatsData!")
		return
	
	match persistence_policy:
		PersistencePolicy.ALWAYS_FULL: _reset_to_max()
		PersistencePolicy.PERSIST_STATE: _load_from_state()


func modify(stat: String, amount: int):
	var new_value = current_values[stat] + amount
	
	if limits.has(stat):
		new_value = clamp(new_value, 0, limits[stat])
		
	if current:
		current.set(stat, current_values[stat])
		is_current_dirty = true
	
	if current_values[stat] == limits[stat]:
		stat_full.emit(stat)
	
	if current_values[stat] == 0:
		stat_empty.emit(stat)
	
	stat_changed.emit(stat, current_values[stat])


func update_max(stat: String, new_max: int) -> void:
	limits[stat] = new_max
	stats.set(stat, new_max)


#=======================================================
#             Loading Stats from Files
#=======================================================


func _reset_to_max() -> void:
	for prop in stats.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var stat_name = prop.name
			var max_val = stats.get(stat_name)
			limits[stat_name] = max_val
			current_values[stat_name] = max_val


func _load_from_state() -> void:
	for prop in stats.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			limits[prop.name] = stats.get(prop.name)
	
	if current:
		for prop in current.get_property_list():
			if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				var stat_name = prop.name
				current_values[stat_name] = current.get(stat_name)
	else:
		push_warning("PERSIST_STATE selected but 'current' is empty.")
		_reset_to_max()


#=======================================================
#             Save Stats in Files
#=======================================================


func save_files() -> void:
	if is_current_dirty:
		for stat in current_values:
			current.set(stat, current_values[stat])
		_save_resource_file(current)
		is_current_dirty = false
	
	if is_limits_dirty:
		for stat in limits:
			stats.set(stat, limits[stat])
		_save_resource_file(stats)
		is_limits_dirty = false


func _save_resource_file(res: Resource):
	var error = ResourceSaver.save(res)
	if error != Error.OK:
		push_error("Error saving stats: " + str(error))
