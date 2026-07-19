## Resource base class representing an inventory item.
##
## To use:
## 1. Create custom resources (.tres) extending or using this class directly.
## 2. Configure item properties such as name, icon, stack size, and description.
class_name Item extends Resource

## The user-facing name of the item.
@export var name: String

## The icon texture used to represent the item in the UI.
@export var icon: Texture2D

## The maximum stack size for this item in a single slot.
@export var max_stack: int = 1

## A descriptive text about the item.
@export_multiline("Description of the item") var description: String

## Custom data resources associated with this item for extensibility.
@export var data: Array[Resource]
