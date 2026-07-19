class_name StatsComponent extends Node

signal stat_changed(stat_name: StringName, value: float)

@export var armor: float = 10.0:
	set(value):
		armor = value
		stat_changed.emit(&"armor", armor)

@export var magic_resist: float = 10.0:
	set(value):
		magic_resist = value
		stat_changed.emit(&"magic_resist", magic_resist)

@export var penetration: float = 0.0:
	set(value):
		penetration = value
		stat_changed.emit(&"penetration", penetration)

# Modifiers dictionary for dynamically adding status effects/buffs/debuffs
var modifiers: Dictionary = {}


func add_modifier(stat_name: StringName, id: String, value: float) -> void:
	if not modifiers.has(stat_name):
		modifiers[stat_name] = {}
	modifiers[stat_name][id] = value
	_recalculate_stat(stat_name)


func remove_modifier(stat_name: StringName, id: String) -> void:
	if modifiers.has(stat_name) and modifiers[stat_name].has(id):
		modifiers[stat_name].erase(id)
		_recalculate_stat(stat_name)


func get_modified_value(stat_name: StringName) -> float:
	var base_val = get(stat_name)
	if base_val == null:
		return 0.0
		
	var bonus = 0.0
	if modifiers.has(stat_name):
		for key in modifiers[stat_name]:
			bonus += modifiers[stat_name][key]
			
	return base_val + bonus


func _recalculate_stat(stat_name: StringName) -> void:
	# Trigger set/get or emit change
	stat_changed.emit(stat_name, get_modified_value(stat_name))
