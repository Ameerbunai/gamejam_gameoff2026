
extends RigidBody3D

@export var boost_strength: float = 12.0
@export var hold_offset: Vector3 = Vector3(0.35, -0.25, -0.7)
@export var hold_rotation_degrees: Vector3 = Vector3(0, -90, 0)

var held: bool = false
var holder_camera: Camera3D
var holder: CharacterBody3D

var original_collision_layer: int
var original_collision_mask: int
@export var muzzle_flash: GPUParticles3D
@export var muzzle_light: OmniLight3D

func _ready() -> void:
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	

func try_pickup(camera: Camera3D, player: CharacterBody3D) -> void:
	if held:
		return

	held = true
	holder_camera = camera
	holder = player

	freeze = true
	sleeping = false

	collision_layer = 0
	collision_mask = 0

	print("MOVEMENT GUN PICKED UP")



func drop_block() -> void:
	if not held:
		return

	held = false
	freeze = false
	sleeping = false
	gravity_scale = 1.0
	can_sleep = false

	collision_layer = original_collision_layer
	collision_mask = original_collision_mask

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	holder_camera = null
	holder = null

	print("GUN DROPPED")


func _physics_process(_delta: float) -> void:
	if not held:
		return

	if not is_instance_valid(holder_camera):
		drop_block()
		return

	var camera_basis := holder_camera.global_basis

	global_position = (
		holder_camera.global_position
		+ camera_basis * hold_offset
	)

	global_basis = (
		camera_basis
		* Basis.from_euler(
			Vector3(
				deg_to_rad(hold_rotation_degrees.x),
				deg_to_rad(hold_rotation_degrees.y),
				deg_to_rad(hold_rotation_degrees.z)
			)
		)
	)


func shoot(camera: Camera3D) -> void:
	if not held or not is_instance_valid(holder):
		return

	play_shoot_effect()

	var shot_direction := -camera.global_basis.z
	var recoil_direction := -shot_direction

	holder.apply_movement_boost(recoil_direction, boost_strength)

	print("RECOIL BLAST!")
func play_shoot_effect() -> void:
	if is_instance_valid(muzzle_flash):
		muzzle_flash.restart()
		muzzle_flash.emitting = true

	if is_instance_valid(muzzle_light):
		muzzle_light.visible = true
		muzzle_light.light_energy = 3.0

		var tween := create_tween()
		tween.tween_property(
			muzzle_light,
			"light_energy",
			0.0,
			0.12
		)

		tween.tween_callback(_hide_muzzle_light)
func _hide_muzzle_light() -> void:
	muzzle_light.visible = false
