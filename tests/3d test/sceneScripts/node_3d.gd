extends Node3D

func _on_interactable_3d_interacted(_player: Node) -> void:
	queue_free()
