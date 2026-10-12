# Inventory System

A modular, slot-based inventory component system driven by Godot `Resource` definitions for items and slots.

---

## 📄 Core Scripts

### 1. `Item` (`Item.gd` - `Resource`)
Base data blueprint representing an item definition.
* `name: String`: Display name of the item.
* `icon: Texture2D`: Icon graphic for inventory UIs.
* `max_stack: int`: Maximum number of units allowed per inventory slot.
* `description: String`: Flavor or description text.
* `data: Array[Resource]`: Array of custom attached resources (e.g. status effects like `burn.tres`, weapon stats, audio cues).

### 2. `InventorySlot` (`InventorySlot.gd` - `Resource`)
Represents an individual slot inside an inventory.
* `item: Item`: Reference to the `Item` resource.
* `quantity: int`: Current stack count in this slot.

### 3. `InventoryComponent` (`InventoryComponent.gd` - `Node`)
Runtime component attached to actors, chests, or dropped bags.
* `max_slots: int`: Capacity limit for the inventory (default: 10).
* `slots: Array[InventorySlot]`: Current list of filled slots.
* **Signals**:
  * `inventory_changed`: Emitted whenever items are added, removed, or cleared.
* **Methods**:
  * `add_item(item: Item, amount: int = 1) -> bool`: Adds items, filling existing stacks first up to `item.max_stack`, then creating new slots. Returns `false` if inventory is full.
  * `remove_item_from_slot(slot: InventorySlot, amount: int = 1) -> void`: Decrements slot quantity and erases the slot if count reaches 0.
  * `clar_slot(slot: InventorySlot) -> void`: Removes a specific slot completely.
  * `clear_inventory() -> void`: Empties all slots.
  * `get_items() -> Array[InventorySlot]`: Returns the array of current slots.

---

## 🧪 Usage Example (from `tests/2d test`)

### 1. Defining Items
Create a new `Item` resource in the FileSystem dock (e.g., [`tests/2d test/inventorySystem/SwordItem.tres`](../../tests/2d%20test/inventorySystem/SwordItem.tres)):
* `name`: `"FireSword"`
* `max_stack`: `1`
* `description`: `"A normal sword, the swordest sword of all swords."`
* `data`: `[burn.tres]` (Attaching custom resources or status effects directly to items!)

### 2. Equipping Inventory to Player
In [`tests/2d test/player.tscn`](../../tests/2d%20test/player.tscn), add `InventoryComponent` as a child node.

```gdscript
extends CharacterBody2D

@export var inventory: InventoryComponent

func _ready() -> void:
    inventory.inventory_changed.connect(_update_ui)

func pickup_item(item: Item, amount: int) -> void:
    var success = inventory.add_item(item, amount)
    if not success:
        print("Inventory is full!")

func _update_ui() -> void:
    for slot in inventory.get_items():
        print("Slot item: %s, quantity: %d" % [slot.item.name, slot.quantity])
```
