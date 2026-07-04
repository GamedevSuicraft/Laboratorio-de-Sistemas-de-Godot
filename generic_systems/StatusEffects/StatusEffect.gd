## Resource template class for our effect's metadata

class_name StatusEffect extends Resource

# General information of our effect
@export var effect_id: String
@export var duration: float
@export var tick_rate: float

# Command Pattern for our effect behaviour
@export var behaviour_script: GDScript 
