extends Node3D

@export var background_music: AudioStream

func _ready() -> void:
	if background_music:
		AudioManager.play_music(background_music)
