class_name ButtonController
extends Node3D


signal state_changed(is_pressed: bool)

enum ButtonType {
	MOMENTARY,
	PERMANENT
}

enum ButtonState {
	UNPRESSED = 0,
	PRESSED = 1
}

@export_group("Button Configuration")
@export var button_type: ButtonType = ButtonType.MOMENTARY
@export var current_state: ButtonState = ButtonState.UNPRESSED

@export_group("Visuals & Animation")
## Arraste aqui a Mesh/Modelo visual que se move ao carregar.
@export var mesh_to_animate: Node3D
@export var press_offset: Vector3 = Vector3(0, -0.15, 0)
@export var animation_duration: float = 0.12

@export_group("Audio")
@export var press_sound: AudioStream
@export var release_sound: AudioStream

var _original_position: Vector3
var _tween: Tween

func _ready() -> void:
	if mesh_to_animate:
		_original_position = mesh_to_animate.position
	
	# Se já começar pressionado por defeito:
	if current_state == ButtonState.PRESSED:
		_apply_visual_state(true, false)

# ==============================================================================
# SINAIS VINDOS DO DETECTOR (PressurePlateLogic)
# ==============================================================================

func _on_pressure_plate_pressed() -> void:
	if current_state == ButtonState.PRESSED:
		return
		
	current_state = ButtonState.PRESSED
	_animate_mesh(_original_position + press_offset)
	
	if press_sound:
		AudioManager.play_sfx_3d(press_sound, global_position)
		
	state_changed.emit(true)

func _on_pressure_plate_released() -> void:
	if button_type == ButtonType.PERMANENT:
		return
		
	if current_state == ButtonState.UNPRESSED:
		return
		
	current_state = ButtonState.UNPRESSED
	_animate_mesh(_original_position)
	
	if release_sound:
		AudioManager.play_sfx_3d(release_sound, global_position)
		
	state_changed.emit(false)

# ==============================================================================
# ANIMAÇÃO (TWEEN)
# ==============================================================================

func _animate_mesh(target_pos: Vector3) -> void:
	if not mesh_to_animate:
		return
		
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(mesh_to_animate, "position", target_pos, animation_duration)

func _apply_visual_state(is_pressed_visual: bool, animated: bool = true) -> void:
	if not mesh_to_animate:
		return
	var target_pos := _original_position + (press_offset if is_pressed_visual else Vector3.ZERO)
	if animated:
		_animate_mesh(target_pos)
	else:
		mesh_to_animate.position = target_pos
