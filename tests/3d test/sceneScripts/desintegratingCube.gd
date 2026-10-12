extends CSGSphere3D

var mat: ShaderMaterial
@export var desolve_speed: float = 0.5
@export var animation_stating_point: float = 0

@export var explosion_sound: AudioStream

func _ready() -> void:
	# Obtém o material do próprio nó e converte para ShaderMaterial
	mat = material as ShaderMaterial
	
	# Exemplo: definir o valor imediatamente para 0.5
	if mat:
		mat.set_shader_parameter("dissolve_amount", animation_stating_point)

# Atualizar frame a frame (ex: com um temporizador ou tecla)
func _process(delta: float) -> void:
	if mat: # Barra de espaço / Enter
		var current_val: float = mat.get_shader_parameter("dissolve_amount")
		mat.set_shader_parameter("dissolve_amount", current_val + delta * desolve_speed)
	
		if current_val >= 1:
			AudioManager.play_sfx_3d(explosion_sound, self.global_position)
			queue_free()
