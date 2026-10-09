extends CSGPolygon3D

var mat: ShaderMaterial
@export var desolve_speed: float = 0.5

func _ready() -> void:
	# Obtém o material do próprio nó e converte para ShaderMaterial
	mat = material as ShaderMaterial
	
	# Exemplo: definir o valor imediatamente para 0.5
	if mat:
		mat.set_shader_parameter("dissolve_amount", 0)

# Atualizar frame a frame (ex: com um temporizador ou tecla)
func _process(delta: float) -> void:
	if mat: # Barra de espaço / Enter
		var current_val: float = mat.get_shader_parameter("dissolve_amount")
		mat.set_shader_parameter("dissolve_amount", current_val + delta * desolve_speed)
	
		print(current_val)
	
		if current_val >= 1:
			queue_free()
