class_name Projectile3D
extends Node3D
## A generic, modular 3D projectile component using frame-by-frame raycasting
## to guarantee accurate hit detection at any speed without tunneling.

## Emitted when the projectile hits a surface or target.
signal impacted(collider: Object, hit_position: Vector3, hit_normal: Vector3)

## Emitted when the projectile's lifetime expires without hitting anything (or after all bounces).
signal expired()


# ============================================================================
# MOVEMENT PARAMETERS
# ============================================================================
@export_group("Movement")

## Initial forward speed in meters per second.
@export_range(0.0, 500.0, 0.5) var speed: float = 40.0

## Acceleration applied per second (positive = speeds up like a rocket, negative = slows down).
@export var acceleration: float = 0.0

## Gravity downward pull in m/s² (0.0 = straight laser/ plasma bolt, 9.8 = arcing arrow/grenade).
@export_range(0.0, 50.0, 0.1) var gravity: float = 0.0

## Automatically rotates the projectile mesh to face its current velocity vector (great for arcing arrows).
@export var align_to_velocity: bool = true


# ============================================================================
# HOMING / GUIDANCE PARAMETERS
# ============================================================================
@export_group("Homing")

## Optional target node for homing missiles or magic orbs.
@export var homing_target: Node3D = null

## Turning responsiveness when steering toward the homing_target (0.0 = disabled).
@export_range(0.0, 30.0, 0.1) var homing_turn_speed: float = 0.0


# ============================================================================
# COMBAT & COLLISION PARAMETERS
# ============================================================================
@export_group("Combat & Collision")

## Base damage dealt to targets that implement a `take_damage` method.
@export var damage: float = 25.0

## Maximum time in seconds before the projectile automatically despawns.
@export_range(0.1, 60.0, 0.1) var max_lifetime: float = 5.0

## Physics collision mask used by the raycast to detect walls, enemies, and shields.
@export_flags_3d_physics var collision_mask: int = 1

## Enables raycast detection against Area3D nodes (useful for energy shields and hitboxes).
@export var collide_with_areas: bool = true

## Enables raycast detection against PhysicsBody3D nodes (walls, floors, characters).
@export var collide_with_bodies: bool = true

## Number of times the projectile can ricochet/bounce off surfaces before being destroyed.
@export_range(0, 20, 1) var max_bounces: int = 0

## Speed multiplier retained after each bounce (1.0 = full speed, 0.5 = loses half speed).
@export_range(0.1, 1.0, 0.05) var bounce_bounciness: float = 0.8

## Number of targets the projectile can pierce through before being destroyed.
@export_range(0, 20, 1) var max_pierces: int = 0


# ============================================================================
# VISUAL EFFECTS (VFX)
# ============================================================================
@export_group("Visual Effects")

## Optional scene spawned at the exact impact point (e.g., sparks, explosion, decal).
@export var impact_vfx_scene: PackedScene = null

## Optional trail particles node that should finish emitting gracefully before freeing the node.
@export var trail_particles: GPUParticles3D = null


# ============================================================================
# INTERNAL STATE
# ============================================================================
var _velocity: Vector3 = Vector3.ZERO
var _age: float = 0.0
var _bounces_left: int = 0
var _pierces_left: int = 0
var _excluded_rids: Array[RID] = []
var _is_destroyed: bool = false


# ============================================================================
# LIFECYCLE & INITIALIZATION
# ============================================================================

func _ready() -> void:
	_bounces_left = max_bounces
	_pierces_left = max_pierces
	# Default initial velocity along the node's forward axis (-Z in Godot)
	if _velocity == Vector3.ZERO:
		_velocity = -global_transform.basis.z.normalized() * speed


## Initializes and launches the projectile from a specific transform and optional shooter to ignore.
## Call this right after instantiating the projectile in your weapon script.
func launch(start_transform: Transform3D, shooter: CollisionObject3D = null, custom_speed: float = -1.0) -> void:
	global_transform = start_transform
	var launch_speed: float = custom_speed if custom_speed >= 0.0 else speed
	_velocity = -global_transform.basis.z.normalized() * launch_speed
	
	if shooter:
		add_collision_exception(shooter)


## Adds a physics object (such as the player or turret firing the projectile) to the ignore list.
func add_collision_exception(object: CollisionObject3D) -> void:
	if object and not _excluded_rids.has(object.get_rid()):
		_excluded_rids.append(object.get_rid())


# ============================================================================
# PHYSICS STEP & RAYCAST MOVEMENT
# ============================================================================

func _physics_process(delta: float) -> void:
	if _is_destroyed:
		return

	# 1. Track lifetime
	_age += delta
	if _age >= max_lifetime:
		expired.emit()
		_destroy_projectile()
		return

	# 2. Apply acceleration and gravity
	if acceleration != 0.0:
		_velocity += _velocity.normalized() * (acceleration * delta)
	if gravity != 0.0:
		_velocity.y -= gravity * delta

	# 3. Apply homing steering if a valid target is assigned
	if is_instance_valid(homing_target) and homing_turn_speed > 0.0:
		var current_speed: float = _velocity.length()
		var desired_dir: Vector3 = global_position.direction_to(homing_target.global_position)
		var new_dir: Vector3 = _velocity.normalized().slerp(desired_dir, clampf(homing_turn_speed * delta, 0.0, 1.0))
		_velocity = new_dir * current_speed

	# 4. Calculate frame displacement and perform RayCast between current and next position
	var current_pos: Vector3 = global_position
	var next_pos: Vector3 = current_pos + (_velocity * delta)
	
	var hit: Dictionary = _raycast_step(current_pos, next_pos)
	if not hit.is_empty():
		_handle_impact(hit)
	else:
		global_position = next_pos

	# 5. Rotate mesh to follow velocity arc
	if align_to_velocity and _velocity.length_squared() > 0.01:
		look_at(global_position + _velocity.normalized(), Vector3.UP)


# ============================================================================
# COLLISION & IMPACT HANDLING
# ============================================================================

## Casts a physics ray from `from_pos` to `to_pos` to detect any collision during this frame.
func _raycast_step(from_pos: Vector3, to_pos: Vector3) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from_pos, to_pos, collision_mask, _excluded_rids)
	query.collide_with_areas = collide_with_areas
	query.collide_with_bodies = collide_with_bodies
	return space_state.intersect_ray(query)


## Processes damage, VFX spawning, piercing, and ricochet bounces upon hitting a surface.
func _handle_impact(hit: Dictionary) -> void:
	var collider: Object = hit.get("collider")
	var hit_pos: Vector3 = hit.get("position", global_position)
	var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
	var hit_rid: RID = hit.get("rid", RID())

	# Move projectile to the exact point of impact
	global_position = hit_pos
	impacted.emit(collider, hit_pos, hit_normal)

	# Spawn impact particles/sparks aligned with the surface normal
	if impact_vfx_scene:
		_spawn_impact_vfx(hit_pos, hit_normal)

	# Notify target if it implements standard damage or shield-hit methods
	if is_instance_valid(collider):
		if collider.has_method("on_projectile_hit"):
			collider.call("on_projectile_hit", damage, hit_pos, hit_normal, _velocity.normalized())
		elif collider.has_method("take_damage"):
			collider.call("take_damage", damage)

	# Check for Piercing (pass through target and ignore it on future frames)
	if _pierces_left > 0:
		_pierces_left -= 1
		if hit_rid.is_valid():
			_excluded_rids.append(hit_rid)
		global_position += _velocity.normalized() * 0.05
		return

	# Check for Ricochet / Bounce
	if _bounces_left > 0:
		_bounces_left -= 1
		_velocity = _velocity.bounce(hit_normal) * bounce_bounciness
		global_position = hit_pos + (hit_normal * 0.02) # Offset slightly to prevent self-collision
		return

	# Otherwise, destroy the projectile
	_destroy_projectile()


## Instantiates the impact VFX scene at the collision coordinates oriented along the hit normal.
func _spawn_impact_vfx(pos: Vector3, normal: Vector3) -> void:
	var vfx_instance: Node3D = impact_vfx_scene.instantiate() as Node3D
	if not vfx_instance:
		return
	get_tree().current_scene.add_child(vfx_instance)
	vfx_instance.global_position = pos
	
	# Align VFX with surface normal (handles parallel UP vector edge case)
	if absf(normal.dot(Vector3.UP)) > 0.99:
		vfx_instance.look_at(pos + normal, Vector3.RIGHT)
	else:
		vfx_instance.look_at(pos + normal, Vector3.UP)


## Safely cleans up the projectile while allowing trail particles to finish fading out.
func _destroy_projectile() -> void:
	if _is_destroyed:
		return
	_is_destroyed = true
	set_physics_process(false)

	# Detach and fade out trail particles if present so they don't vanish abruptly
	if is_instance_valid(trail_particles):
		trail_particles.emitting = false
		var trail_lifetime: float = trail_particles.lifetime
		# Hide meshes immediately while waiting for particles to finish
		for child in get_children():
			if child != trail_particles and child is VisualInstance3D:
				child.visible = false
		await get_tree().create_timer(trail_lifetime).timeout

	queue_free()
