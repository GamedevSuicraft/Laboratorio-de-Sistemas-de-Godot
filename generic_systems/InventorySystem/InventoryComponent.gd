class_name InventoryComponent extends Node

signal inventory_changed

@export var max_slots: int = 10
@export var slots: Array[InventorySlot] = []


func add_item(item: GameItem, amount: int = 1) -> bool:
	# add items in existing slots
	for slot in slots:
		if slot.item == item and slot.quantity < item.max_stack:
			var space_left = item.max_stack - slot.quantity
			var amount_to_add = min(amount, space_left)
			slot.quantity += amount_to_add
			amount -= amount_to_add
			inventory_changed.emit()
			if amount <= 0: return true
		
	# if there are items left, place them in empty slots
	while amount > 0:
		if slots.size() < max_slots:
			var new_slot = InventorySlot.new()
			new_slot.item = item
			var add = min(amount, item.max_stack)
			new_slot.quantity = add
			slots.append(new_slot)
			amount -= add
		else:
			return false # inventory full
			
	inventory_changed.emit()
	return true


func remove_item_from_slot(slot: InventorySlot, amount: int = 1):
	if not slots.has(slot):
		print("This slot is not owned by this inventory")
		return
	
	if amount > slot.quantity:
		print("The amount to remove is bigger than the quantity in the slot")
		return
		
	slot.quantity -= amount
	
	if slot.quantity <= 0:
		slots.erase(slot)	
	
	inventory_changed.emit()


func clar_slot(slot: InventorySlot) -> void:
	if slots.has(slot):
		slots.erase(slot)
		inventory_changed.emit()


func clear_inventory() -> void:
	slots.clear()
	inventory_changed.emit()
