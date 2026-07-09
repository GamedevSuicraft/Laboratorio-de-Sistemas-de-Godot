class_name Interactable2D extends Area2D


signal interacted(player: Node)


func request_interaction(player: Node):
	interacted.emit(player)
