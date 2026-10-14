extends DirectionalLight3D

## Reference to your WorldEnvironment so the script can sync the sky shader even when the sun is turned off at night.
@export var world_environment: WorldEnvironment

## Enable/Disable day time cycle
@export var enable_day_cycle: bool = true

## Duration of a full 24-hour cycle in real-time seconds.
@export_range(5.0, 600.0, 1.0) var cycle_duration_seconds: float = 60.0

## Current time of day in hours (0.0 = Midnight, 6.0 = Sunrise, 12.0 = Noon, 18.0 = Sunset).
@export_range(0.0, 24.0, 0.1) var current_time_hours: float = 12.0

## Maximum light energy at midday.
@export var day_light_energy: float = 1.2

## Light color during midday.
@export var day_light_color: Color = Color(1.0, 0.98, 0.92)

## Light color during sunrise and sunset.
@export var sunset_light_color: Color = Color(1.0, 0.45, 0.2)


func _process(delta: float) -> void:
	if not enable_day_cycle:
		return
	
	# 1. Advance time
	current_time_hours = fmod(current_time_hours + (delta * 24.0 / cycle_duration_seconds), 24.0)
	
	# 2. Rotate light: 6h = 0 deg, 12h = -90 deg (pointing down), 18h = -180 deg, 0h = -270 deg (pointing up)
	var sun_angle_deg: float = ((current_time_hours - 6.0) / 24.0) * -360.0
	rotation_degrees.x = sun_angle_deg
	rotation_degrees.y = -30.0
	
	# 3. Calculate Sun Height (+1.0 at Noon, 0.0 at Horizon, -1.0 at Midnight)
	var sun_direction: Vector3 = global_transform.basis.z.normalized()
	var sun_height: float = sun_direction.y
	
	# 4. Prevent light from shining from underneath the ground!
	# When sun_height < 0.0, the sun is below the floor, so we fade light_energy completely to 0.0.
	var sun_above_horizon: float = smoothstep(-0.05, 0.15, sun_height)
	var sunset_factor: float = smoothstep(-0.1, 0.05, sun_height) * (1.0 - smoothstep(0.05, 0.4, sun_height))
	
	light_energy = day_light_energy * sun_above_horizon
	light_color = day_light_color.lerp(sunset_light_color, sunset_factor)
