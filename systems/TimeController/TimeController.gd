class_name TimeController extends Node


const TOTAL_DAY_DURATION: float = 86400.0

@export var day_duration_minutes: float = 10.0
@export var debug_time: bool = false
@export_range(0, TOTAL_DAY_DURATION, 1.0) var time_of_day: float = TOTAL_DAY_DURATION / 2

signal time_changed(current_time: float)


func _process(delta: float) -> void:
	var seconds_per_real_second = TOTAL_DAY_DURATION / (day_duration_minutes * 60.0)
	time_of_day += delta * seconds_per_real_second
	
	if time_of_day >= TOTAL_DAY_DURATION:
		time_of_day = fmod(time_of_day, TOTAL_DAY_DURATION)
		
	time_changed.emit(time_of_day)
	if debug_time:
		print("TimeController Debug - time of day: ", time_of_day)
		print("%02d:%02d" % [get_hours(), get_minutes()])


#====================================
#          Utility Methods
#====================================


func get_normalized_time() -> float:
	return time_of_day / TOTAL_DAY_DURATION # Retorna 0.0 a 1.0 (0.5 é meio-dia)


func get_hours() -> int:
	return int(time_of_day / 3600.0)


func get_minutes() -> int:
	return int(fmod(time_of_day, 3600.0) / 60.0)
 

func set_time_with_clock_time(hours: int, minutes: int):
	var h = posmod(hours, 24)
	var m = posmod(minutes, 60)
	time_of_day = 3600 * h + 60 * m
	time_changed.emit(time_of_day)
