class_name StatusEffectManager extends Node


signal effect_applied(effect_id: String)
signal effect_expired(effect_id: String)
signal effect_ticked(effect_id: String)


var active_effects: Array[StatusEffect] = []


func add_effect(effect: StatusEffect):
	var effect_data = {
		"resource": effect,
		"time_left": effect.duration,
		"last_tick": 0.0
	}
	active_effects.append(effect_data)
	effect_applied.emit(effect.effect_id)


func _process(delta: float) -> void:
	for i in range(active_effects.size() - 1, -1, -1):
		# update effect timers
		var effect_data = active_effects[i]
		effect_data.time_left -= delta
		effect_data.last_tick += delta
		
		# trigger status effect after tick rate
		if effect_data.last_tick >= effect_data.resource.tick_rate:
			effect_ticked.emit(effect_data.resource.effect_id)
			effect_data.last_tick = 0
		
		# remove effect after total time ends
		if effect_data.time_left <= 0:
			effect_expired.emit(effect_data.resource.effect_id)
			active_effects.remove_at(i)
