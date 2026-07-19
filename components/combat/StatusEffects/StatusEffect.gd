## Resource template class containing status effect metadata (e.g., duration, tick rate).
##
## To use:
## 1. Create a resource file (.tres) extending this class.
## 2. Configure effect_id, duration, and tick_rate in the inspector.
## 3. Pass this resource to the StatusEffectManager to apply the effect.
class_name StatusEffect extends Resource

## Unique identifier for the status effect.
@export var effect_id: String

## Duration of the status effect in seconds. A value of 0.0 or less means it is instant or infinite.
@export var duration: float

## Interval in seconds between periodic tick executions of this effect.
@export var tick_rate: float
