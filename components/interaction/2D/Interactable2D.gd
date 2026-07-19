## Area2D subclass representing an object that can be interacted with in 2D space.
##
## To use:
## 1. Add this Area2D node to an interactable object (e.g., chest, door).
## 2. Connect to the 'interacted' signal to handle the interaction logic.
class_name Interactable2D extends Area2D


signal interacted(player: Node)


func request_interaction(player: Node):
	interacted.emit(player)
