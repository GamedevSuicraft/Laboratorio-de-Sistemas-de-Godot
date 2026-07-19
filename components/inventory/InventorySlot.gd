## Resource representing a slot inside an inventory, holding a reference to an Item and its current quantity.
##
## To use:
## 1. Typically instantiated by InventoryComponent to track inventory items.
class_name InventorySlot extends Resource

## The number of items stored in this slot.
@export var quantity: int = 0

## The Item resource stored in this slot.
@export var item: Item
