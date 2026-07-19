# Guarde este script como "pressure_plate_logic.gd"
class_name PressurePlateLogic
extends Area3D

signal pressed
signal released

# Configurações visuais que aparecem no Inspetor
@export_group("Animação")
@export var target_node: Node3D # Arraste QUALQUER objeto 3D para aqui
@export var move_offset: Vector3 = Vector3(0, -0.2, 0) # Direção e distância do movimento
@export var duration: float = 0.15

var original_position: Vector3
var bodies_inside: int = 0

func _ready() -> void:
	if target_node:
		original_position = target_node.position
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(_body: Node3D) -> void:
	bodies_inside += 1
	if bodies_inside == 1:
		_animate(original_position + move_offset)
		pressed.emit()

func _on_body_exited(_body: Node3D) -> void:
	bodies_inside -= 1
	if bodies_inside == 0:
		_animate(original_position)
		released.emit()

func _animate(target_pos: Vector3) -> void:
	if target_node:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(target_node, "position", target_pos, duration)
