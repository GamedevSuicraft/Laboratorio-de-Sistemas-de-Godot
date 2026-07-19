## RayCast2D subclass representing the player's interaction source in 2D space.
##
## To use:
## 1. Add this RayCast2D node to the 2D Player character.
## 2. Call try_interaction(self) when the player presses the interaction key.
## 3. Listen to focused_interactable and unfocused_interactable signals to update UI prompts.
class_name Interactor2D extends RayCast2D

signal focused_interactable(node: Node)
signal unfocused_interactable(node: Node)


var _current_focus: Node = null


func _process(_delta: float) -> void:
	var target = get_collider() if is_colliding() else null
	
	if target != _current_focus:
		if _current_focus:
			unfocused_interactable.emit(_current_focus)
			
		_current_focus = target
		
	if _current_focus and _current_focus.is_in_group("Interactable"):
		focused_interactable.emit(_current_focus)


func try_interaction(player: Node):
	if _current_focus and _current_focus is Interactable2D:
		_current_focus.request_interaction(player)
