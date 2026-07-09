class_name Interactable3D extends Area3D


signal interacted(player: Node)


func request_interaction(player: Node):
	interacted.emit(player)
