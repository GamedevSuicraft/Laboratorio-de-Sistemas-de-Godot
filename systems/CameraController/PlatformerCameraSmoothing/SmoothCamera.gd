extends Camera2D

@export_group("Target Settings")
## The target node for the camera to follow (usually a CharacterBody2D).
@export var target: Node2D

@export_group("Movement & Smoothing")
## How fast the camera interpolates towards the target position.
@export var lerp_speed: float = 4.0

## The size of the deadzone box (half-extents on each axis). Keep it small (e.g., 20x15) to keep the player near the center.
@export var deadzone_size: Vector2 = Vector2(20, 15)

@export_group("Look Ahead (Camera Lead)")
## The maximum offset distance the camera moves ahead. Keep it small (e.g., 30.0) for a subtle drift.
@export var look_ahead_amount: float = 30.0

## The vertical multiplier for the look-ahead offset.
@export var look_ahead_y_ratio: float = 0.2

## How fast the look-ahead offset responds to changes in movement direction.
@export var offset_smoothing: float = 1.5

## The minimum horizontal speed threshold of the target to activate look-ahead.
@export var horizontal_threshold: float = 10.0

## The minimum vertical speed threshold of the target to activate look-ahead.
@export var vertical_threshold: float = 50.0

@export_group("Debug")
## Toggles the on-screen debug visualizer overlay.
@export var show_debug_visuals: bool = false

var _tracked_position: Vector2 = Vector2.ZERO
var _current_offset: Vector2 = Vector2.ZERO
var _first_frame: bool = true


func _ready() -> void:
	if target:
		_tracked_position = target.global_position
		global_position = target.global_position
		_first_frame = false


func _process(delta: float) -> void:
	if not target: 
		return
		
	if _first_frame:
		_tracked_position = target.global_position
		global_position = target.global_position
		_first_frame = false
		
	_update_look_ahead(delta)
	_apply_camera_movement(delta)
	
	if show_debug_visuals:
		queue_redraw()


func _update_look_ahead(delta: float) -> void:
	var target_offset = Vector2.ZERO
	
	# Only apply look-ahead if the player is actively pushing the deadzone boundaries
	var diff = target.global_position - _tracked_position
	var pushing_horizontal = abs(diff.x) >= deadzone_size.x - 1.0 # 1.0 pixel tolerance
	var pushing_vertical = abs(diff.y) >= deadzone_size.y - 1.0
	
	# Check if target has a velocity property (duck typing for CharacterBody2D/PhysicsBody2D)
	if "velocity" in target:
		var vel = target.velocity
		if pushing_horizontal and abs(vel.x) > horizontal_threshold:
			# Add deadzone_size.x to look_ahead_amount to overcome the deadzone trail
			target_offset.x = sign(vel.x) * (look_ahead_amount + deadzone_size.x)
		
		if pushing_vertical and abs(vel.y) > vertical_threshold:
			# Add deadzone_size.y to look_ahead_amount to overcome the vertical deadzone trail
			target_offset.y = sign(vel.y) * (look_ahead_amount * look_ahead_y_ratio + deadzone_size.y)
			
	_current_offset = _current_offset.lerp(target_offset, delta * offset_smoothing)


func _apply_camera_movement(delta: float) -> void:
	var target_pos = target.global_position
	var diff = target_pos - _tracked_position
	
	# Check if target is actively moving (near-zero velocity check for recentering)
	var is_moving_x = false
	var is_moving_y = false
	if "velocity" in target:
		var vel = target.velocity
		# We use a very low tolerance (1.0) to detect any movement, preventing recenter while walking
		is_moving_x = abs(vel.x) > 1.0
		is_moving_y = abs(vel.y) > 1.0
	
	# 1. Update tracked position
	if is_moving_x:
		# Pushes the deadzone box center when the target moves outside its boundary
		if abs(diff.x) > deadzone_size.x:
			_tracked_position.x = target_pos.x - sign(diff.x) * deadzone_size.x
	else:
		# Only recenter when the player is completely stopped (idle)
		_tracked_position.x = lerp(_tracked_position.x, target_pos.x, delta * offset_smoothing)
	
	if is_moving_y:
		if abs(diff.y) > deadzone_size.y:
			_tracked_position.y = target_pos.y - sign(diff.y) * deadzone_size.y
	else:
		# Slowly recenter vertically when stopped
		_tracked_position.y = lerp(_tracked_position.y, target_pos.y, delta * offset_smoothing)

	# 2. Calculate final target position including the look-ahead offset
	var final_target_pos = _tracked_position + _current_offset
	
	# 3. Smoothly interpolate the camera's global position
	global_position = global_position.lerp(final_target_pos, lerp_speed * delta)


func _draw() -> void:
	if not show_debug_visuals:
		return
		
	# Draw the deadzone boundary box (Green)
	var relative_tracked = _tracked_position - global_position
	var deadzone_rect = Rect2(relative_tracked - deadzone_size, deadzone_size * 2)
	draw_rect(deadzone_rect, Color(0.2, 0.8, 0.2, 0.4), false, 2.0)
	
	# Draw the target position including look-ahead offset (Red cross)
	var final_target = _tracked_position + _current_offset
	var relative_target = final_target - global_position
	draw_line(relative_target - Vector2(12, 0), relative_target + Vector2(12, 0), Color(0.8, 0.2, 0.2, 0.8), 2.0)
	draw_line(relative_target - Vector2(0, 12), relative_target + Vector2(0, 12), Color(0.8, 0.2, 0.2, 0.8), 2.0)
	
	# Draw the camera's actual center position (Blue circle)
	draw_circle(Vector2.ZERO, 5.0, Color(0.2, 0.6, 1.0, 0.9))
