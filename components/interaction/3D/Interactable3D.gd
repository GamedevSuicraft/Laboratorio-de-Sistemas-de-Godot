## Area3D subclass representing an object that can be interacted with in 3D space.
##
## To use:
## 1. Add this Area3D node to an interactable object in a 3D scene (e.g., chest, door).
## 2. Connect to the 'interacted' signal to handle the interaction logic.
class_name Interactable3D extends Area3D


signal interacted(player: Node)


func request_interaction(player: Node):
	interacted.emit(player)
