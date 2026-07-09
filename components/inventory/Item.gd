class_name Item extends Resource

@export var name: String
@export var icon: Texture2D
@export var max_stack: int = 1
@export_multiline("Description of the item") var description: String
@export var data: Array[Resource]
