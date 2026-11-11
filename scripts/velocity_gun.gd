
extends RigidBody3D

@export var boost_strength: float = 12.0
@export var hold_offset: Vector3 = Vector3(0.35, -0.25, -0.7)
@export var hold_rotation_degrees: Vector3 = Vector3(0, -90, 0)

@export var muzzle_flash: GPUParticles3D
@export var muzzle_light: OmniLight3D

# SOUND EFFECTS
@export var shoot_sound: AudioStreamPlayer3D
@export var equip_sound: AudioStreamPlayer3D
@export var angry_sound: AudioStreamPlayer3D

# RAGE SETTINGS
@export var rage_per_minute: float = 10.0
@export var rage_per_shot: float = 10.0
@export var cooldown_time: float = 5.0

# ANGRY SHAKE SETTINGS
@export var shake_position_strength: float = 0.025
@export var shake_rotation_strength: float = 2.0
@export var shake_speed: float = 35.0

var rage: float = 0.0
var rage_locked: bool = false
var rage_cooldown: float = 0.0

var held: bool = false
var holder_camera: Camera3D
var holder: CharacterBody3D

var original_collision_layer: int
var original_collision_mask: int

var hold_rage_timer: float = 0.0
var shake_timer: float = 0.0

var gun_meshes: Array[MeshInstance3D] = []
var original_materials: Array[Material] = []


func _ready() -> void:
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask

	find_gun_meshes(self)


func find_gun_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			gun_meshes.append(child)
			original_materials.append(child.material_override)

		find_gun_meshes(child)


func _process(delta: float) -> void:
	if held and not rage_locked:
		hold_rage_timer += delta

		if hold_rage_timer >= 60.0:
			hold_rage_timer -= 60.0
			add_rage(rage_per_minute)

	if not held and rage_cooldown > 0.0:
		rage_cooldown -= delta

		if rage_cooldown <= 0.0:
			rage = 0.0
			rage_locked = false
			shake_timer = 0.0

			update_gun_appearance()

			print("GUN CALMED DOWN")


func add_rage(amount: float) -> void:
	if rage_locked:
		return

	rage = min(rage + amount, 100.0)

	print("GUN RAGE: ", rage, "%")

	if rage >= 100.0:
		rage_locked = true
		shake_timer = 0.0

		play_sound(angry_sound)

		print("THE GUN IS FURIOUS!")

	update_gun_appearance()


func update_gun_appearance() -> void:
	for i in range(gun_meshes.size()):
		var gun_mesh := gun_meshes[i]

		if rage_locked:
			var angry_material := StandardMaterial3D.new()
			angry_material.albedo_color = Color.RED
			angry_material.metallic = 0.5

			gun_mesh.material_override = angry_material
		else:
			gun_mesh.material_override = original_materials[i]


# =========================
# PICKUP
# =========================

func try_pickup(camera: Camera3D, player: CharacterBody3D) -> void:
	if held:
		return

	held = true
	holder_camera = camera
	holder = player

	rage_cooldown = 0.0
	hold_rage_timer = 0.0
	shake_timer = 0.0

	freeze = true
	sleeping = false

	collision_layer = 0
	collision_mask = 0

	play_sound(equip_sound)

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

	rage_cooldown = cooldown_time
	shake_timer = 0.0

	print("GUN DROPPED")


# =========================
# HOLDING AND SHAKING
# =========================

func _physics_process(delta: float) -> void:
	if not held:
		return

	if not is_instance_valid(holder_camera):
		drop_block()
		return

	var camera_basis := holder_camera.global_basis

	var local_position_offset := hold_offset
	var local_rotation_offset := Vector3(
		deg_to_rad(hold_rotation_degrees.x),
		deg_to_rad(hold_rotation_degrees.y),
		deg_to_rad(hold_rotation_degrees.z)
	)

	# Angry shaking
	if rage_locked:
		shake_timer += delta

		var shake_x := sin(shake_timer * shake_speed)
		var shake_y := sin(shake_timer * shake_speed * 1.37)
		var shake_z := sin(shake_timer * shake_speed * 0.83)

		local_position_offset += Vector3(
			shake_x,
			shake_y,
			shake_z
		) * shake_position_strength

		local_rotation_offset += Vector3(
			shake_y,
			shake_z,
			shake_x
		) * deg_to_rad(shake_rotation_strength)

	else:
		shake_timer = 0.0

	global_position = (
		holder_camera.global_position
		+ camera_basis * local_position_offset
	)

	global_basis = (
		camera_basis
		* Basis.from_euler(local_rotation_offset)
	)


# =========================
# SHOOTING
# =========================

func shoot(camera: Camera3D) -> void:
	if not held or not is_instance_valid(holder):
		return

	if rage_locked:
		print("GUN REFUSES TO SHOOT. TOO ANGRY!")
		return

	add_rage(rage_per_shot)

	play_sound(shoot_sound)
	play_shoot_effect()

	var shot_direction := -camera.global_basis.z
	var recoil_direction := -shot_direction

	holder.apply_movement_boost(recoil_direction, boost_strength)

	print("RECOIL BLAST!")


# =========================
# SOUND SYSTEM
# =========================

func play_sound(sound: AudioStreamPlayer3D) -> void:
	if not is_instance_valid(sound):
		return

	if sound.stream == null:
		return

	sound.play()


# =========================
# MUZZLE EFFECTS
# =========================

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
	if is_instance_valid(muzzle_light):
		muzzle_light.visible = false
