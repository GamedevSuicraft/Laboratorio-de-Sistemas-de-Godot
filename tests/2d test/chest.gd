extends Node2D


func _on_interactable_interacted(player: Node) -> void:
	print("O bau foi aberto por: ", player)
