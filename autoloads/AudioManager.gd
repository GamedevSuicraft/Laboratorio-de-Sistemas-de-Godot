extends Node

## Centralized audio manager supporting global, UI, 2D, and 3D positional audio.
## Handles automatic memory cleanup, pitch variation, and bus limiting.
##[br][br]
## [b]Note:[/b] This script must be registered as an Autoload named [code]AudioManager[/code].

const MASTER_BUS: StringName = &"Master"
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
const UI_BUS: StringName = &"UI"

var _music_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_master_limiter()
	_setup_music_player()

## Configures a fallback limiter effect on the Master bus to prevent audio clipping.
func _setup_master_limiter() -> void:
	var master_idx := AudioServer.get_bus_index(MASTER_BUS)
	if master_idx == -1:
		return
		
	var has_limiter := false
	for i in AudioServer.get_bus_effect_count(master_idx):
		if AudioServer.get_bus_effect(master_idx, i) is AudioEffectLimiter:
			has_limiter = true
			break
			
	if not has_limiter:
		var limiter := AudioEffectLimiter.new()
		limiter.ceiling_db = -0.5
		limiter.threshold_db = -1.0
		AudioServer.add_bus_effect(master_idx, limiter)

## Initializes the persistent background music player.
func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

# ==============================================================================
# UI & GLOBAL AUDIO
# ==============================================================================

## Plays a non-positional UI sound effect routed to the UI bus.
## Automatically frees the player node once playback finishes.
##[br][br]
## [b]Parameters:[/b][br]
## • [param stream]: The [AudioStream] resource to play.[br]
## • [param volume_db]: Volume offset in decibels.[br]
## • [param pitch_scale]: Pitch and playback speed scale.[br]
##[br][br]
## [b]Returns:[/b] The spawned [AudioStreamPlayer], or [code]null[/code] if invalid.
func play_ui(
	stream: AudioStream,
	volume_db: float = 0.0,
	pitch_scale: float = 1.0
) -> AudioStreamPlayer:
	if not stream:
		return null
		
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = UI_BUS
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	
	player.finished.connect(player.queue_free)
	player.play()
	return player

# ==============================================================================
# SFX PLAYBACK
# ==============================================================================

## Plays a standard global sound effect with randomized pitch variation.
## Automatically frees the player node once playback finishes.
##[br][br]
## [b]Parameters:[/b][br]
## • [param stream]: The [AudioStream] resource to play.[br]
## • [param pitch_min]: Minimum random pitch multiplier.[br]
## • [param pitch_max]: Maximum random pitch multiplier.[br]
## • [param volume_db]: Volume offset in decibels.[br]
## • [param bus]: Target audio bus name.[br]
##[br][br]
## [b]Returns:[/b] The spawned [AudioStreamPlayer], or [code]null[/code] if invalid.
func play_sfx(
	stream: AudioStream,
	pitch_min: float = 0.9,
	pitch_max: float = 1.1,
	volume_db: float = 0.0,
	bus: StringName = SFX_BUS
) -> AudioStreamPlayer:
	if not stream:
		return null
		
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	add_child(player)
	
	player.finished.connect(player.queue_free)
	player.play()
	return player


## Plays a 2D positional sound effect in world space.
## Automatically frees the player node once playback finishes.
##[br][br]
## [b]Parameters:[/b][br]
## • [param stream]: The [AudioStream] resource to play.[br]
## • [param global_pos]: Coordinates in global 2D space.[br]
## • [param parent]: Optional [Node2D] to attach the player to.[br]
## • [param pitch_min]: Minimum random pitch multiplier.[br]
## • [param pitch_max]: Maximum random pitch multiplier.[br]
## • [param volume_db]: Volume offset in decibels.[br]
## • [param max_distance]: Maximum audible distance in pixels.[br]
##[br][br]
## [b]Returns:[/b] The spawned [AudioStreamPlayer2D], or [code]null[/code] if invalid.
func play_sfx_2d(
	stream: AudioStream,
	global_pos: Vector2,
	parent: Node2D = null,
	pitch_min: float = 0.9,
	pitch_max: float = 1.1,
	volume_db: float = 0.0,
	max_distance: float = 2000.0
) -> AudioStreamPlayer2D:
	if not stream:
		return null
		
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = SFX_BUS
	player.volume_db = volume_db
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.max_distance = max_distance
	
	if parent and is_instance_valid(parent):
		parent.add_child(player)
		player.global_position = global_pos
	else:
		add_child(player)
		player.global_position = global_pos
		
	player.finished.connect(player.queue_free)
	player.play()
	return player


## Plays a 3D positional sound effect in world space.
## Requires an active [AudioListener3D] in the scene to be heard.
## Automatically frees the player node once playback finishes.
##[br][br]
## [b]Parameters:[/b][br]
## • [param stream]: The [AudioStream] resource to play.[br]
## • [param global_pos]: Coordinates in global 3D space.[br]
## • [param parent]: Optional [Node3D] to attach the player to.[br]
## • [param pitch_min]: Minimum random pitch multiplier.[br]
## • [param pitch_max]: Maximum random pitch multiplier.[br]
## • [param volume_db]: Volume offset in decibels.[br]
## • [param unit_size]: Distance attenuation factor in meters.[br]
## • [param max_distance]: Hard cutoff distance in meters (0.0 = infinite falloff).[br]
##[br][br]
## [b]Returns:[/b] The spawned [AudioStreamPlayer3D], or [code]null[/code] if invalid.
func play_sfx_3d(
	stream: AudioStream,
	global_pos: Vector3,
	parent: Node3D = null,
	pitch_min: float = 0.9,
	pitch_max: float = 1.1,
	volume_db: float = 0.0,
	unit_size: float = 10.0,
	max_distance: float = 0.0
) -> AudioStreamPlayer3D:
	if not stream:
		return null
		
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = SFX_BUS
	player.volume_db = volume_db
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.unit_size = unit_size
	player.max_distance = max_distance
	
	if parent and is_instance_valid(parent):
		parent.add_child(player)
		player.global_position = global_pos
	else:
		add_child(player)
		player.global_position = global_pos
		
	player.finished.connect(player.queue_free)
	player.play()
	return player

# ==============================================================================
# MUSIC CONTROLS
# ==============================================================================

## Starts playing a background music track.
## If the requested stream is already playing, the call is safely ignored.
##[br][br]
## [b]Parameters:[/b][br]
## • [param stream]: The [AudioStream] music resource to play.[br]
## • [param volume_db]: Playback volume offset in decibels.[br]
func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	if _music_player.stream == stream and _music_player.playing:
		return
		
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()


## Stops background music playback, with optional fade-out interpolation.
##[br][br]
## [b]Parameters:[/b][br]
## • [param fade_duration]: Duration in seconds to fade out before stopping (0.0 for immediate).[br]
func stop_music(fade_duration: float = 0.0) -> void:
	if not _music_player.playing:
		return
		
	if fade_duration <= 0.0:
		_music_player.stop()
		return
		
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
	tween.finished.connect(func():
		_music_player.stop()
		_music_player.volume_db = 0.0
	)

# ==============================================================================
# BUS & VOLUME HELPERS
# ==============================================================================

## Sets audio bus volume linearly.
##[br][br]
## [b]Parameters:[/b][br]
## • [param bus_name]: Name of the target audio bus.[br]
## • [param linear_volume]: Scalar volume value between 0.0 and 1.0.[br]
func set_bus_volume_linear(bus_name: StringName, linear_volume: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clampf(linear_volume, 0.0001, 1.0)))


## Returns the current bus volume as a linear scalar.
##[br][br]
## [b]Parameters:[/b][br]
## • [param bus_name]: Name of the target audio bus.[br]
##[br][br]
## [b]Returns:[/b] Float between 0.0 and 1.0.
func get_bus_volume_linear(bus_name: StringName) -> float:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return 0.0


## Toggles mute on the specified audio bus.
##[br][br]
## [b]Parameters:[/b][br]
## • [param bus_name]: Name of the target audio bus.[br]
## • [param muted]: True to mute the bus, false to unmute.[br]
func set_bus_mute(bus_name: StringName, muted: bool) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, muted)
