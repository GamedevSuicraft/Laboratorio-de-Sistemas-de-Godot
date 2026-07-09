@icon("./stats.svg")
class_name StatsManager extends Node

signal stat_changed(stat_name: String, current_value: int)
signal stat_full(stat_name: String)
signal stat_empty(stat_name: String)

@export var stats: StatsData
var current_values: Dictionary = {}
var limits: Dictionary = {}


func _ready() -> void:
	if not stats:
		push_error("StatManager needs a StatsData!")
		return
		
	for prop in stats.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var stat_name = prop.name
			var max_val = stats.get(stat_name)
			limits[stat_name] = max_val
			current_values[stat_name] = max_val


func modify(stat: String, amount: int):
	current_values[stat] += amount
	
	if limits.has(stat):
		current_values[stat] = clamp(current_values[stat], 0, limits[stat])
		
	if current_values[stat] == limits[stat]:
		stat_full.emit(stat)
		
	if current_values[stat] == 0:
		stat_empty.emit(stat)

	stat_changed.emit(stat, current_values[stat])
