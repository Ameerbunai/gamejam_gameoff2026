
extends RigidBody3D

@export var default_texture: Texture2D
@export var past_texture: Texture2D
@export var future_texture: Texture2D

enum AgeState {
	DEFAULT,
	PAST,
	FUTURE
}

# Player pickup
var held: bool = false
var player_camera: Camera3D
var player_body: CharacterBody3D

# Robot pickup
var robot_held: bool = false
var robot_hand: Node3D
var saved_collision_layer: int
var saved_collision_mask: int

@export var hold_distance: float = 2.5
@export var follow_speed: float = 12.0

# Ageing properties
@export var default_mass: float = 2.0
@export var past_mass: float = 5.0
@export var future_mass: float = 0.5

@export var default_size: Vector3 = Vector3.ONE
@export var past_size: Vector3 = Vector3(1.0, 1.5, 1.0)
@export var future_size: Vector3 = Vector3(0.6, 0.6, 0.6)

var age_state: AgeState = AgeState.DEFAULT

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $CollisionShape3D

var default_material := StandardMaterial3D.new()
var past_material := StandardMaterial3D.new()
var future_material := StandardMaterial3D.new()


func _ready() -> void:
	contact_monitor = true

	default_material.albedo_color = Color(0.55, 0.55, 0.55)
	past_material.albedo_color = Color.BLACK
	future_material.albedo_color = Color(0.36, 0.18, 0.08)

	apply_age(AgeState.DEFAULT)


# PLAYER PICKUP
func try_pickup(camera: Camera3D, body: CharacterBody3D) -> void:
	if held or robot_held:
		return

	held = true
	player_camera = camera
	player_body = body

	gravity_scale = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true

	print("BLOCK PICKED UP")


# PLAYER DROP
func drop_block() -> void:
	if not held:
		return

	held = false
	freeze = false
	gravity_scale = 1.0

	player_camera = null
	player_body = null

	print("BLOCK DROPPED")


# ROBOT PICKUP
func robot_pickup(hand: Node3D) -> bool:
	if held or robot_held:
		return false

	robot_held = true
	robot_hand = hand

	saved_collision_layer = collision_layer
	saved_collision_mask = collision_mask

	gravity_scale = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true

	collision_layer = 0
	collision_mask = 0

	print("ROBOT STOLE THE BLOCK!")
	return true


# ROBOT DROP
func robot_drop(drop_velocity: Vector3 = Vector3.ZERO) -> void:
	if not robot_held:
		return

	robot_held = false
	robot_hand = null

	freeze = false
	gravity_scale = 1.0

	collision_layer = saved_collision_layer
	collision_mask = saved_collision_mask

	linear_velocity = drop_velocity

	print("ROBOT DROPPED THE BLOCK!")


# FOLLOW HOLDER
func _physics_process(delta: float) -> void:
	if held and is_instance_valid(player_camera):
		var target_position: Vector3 = (
			player_camera.global_position
			- player_camera.global_basis.z * hold_distance
		)

		global_position = global_position.lerp(
			target_position,
			min(follow_speed * delta, 1.0)
		)

	elif robot_held and is_instance_valid(robot_hand):
		global_transform = robot_hand.global_transform


# AGEING CONTROLS
func past() -> void:
	apply_age(AgeState.PAST)


func future() -> void:
	apply_age(AgeState.FUTURE)


func reset_age() -> void:
	apply_age(AgeState.DEFAULT)


# APPLY AGE
func apply_age(state: AgeState) -> void:
	age_state = state

	var new_material := StandardMaterial3D.new()
	new_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	match state:
		AgeState.DEFAULT:
			mass = default_mass
			mesh.scale = default_size
			collision.scale = default_size
			new_material.albedo_texture = default_texture
			new_material.albedo_color = Color.WHITE
			print("AGE APPLIED: DEFAULT")

		AgeState.PAST:
			mass = past_mass
			mesh.scale = past_size
			collision.scale = past_size
			new_material.albedo_texture = past_texture
			new_material.albedo_color = Color.WHITE
			print("AGE APPLIED: PAST")

		AgeState.FUTURE:
			mass = future_mass
			mesh.scale = future_size
			collision.scale = future_size
			new_material.albedo_texture = future_texture
			new_material.albedo_color = Color.WHITE
			print("AGE APPLIED: FUTURE")

	mesh.material_override = new_material

	if mesh.mesh is BoxMesh:
		mesh.mesh.material = new_material
