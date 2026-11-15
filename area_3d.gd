
extends Area3D

@export var player: CharacterBody3D
@export var cubes: Array[RigidBody3D] = []

var player_start_position: Vector3
var player_start_rotation: Vector3

var cube_start_positions: Array[Vector3] = []
var cube_start_rotations: Array[Vector3] = []

var resetting: Array[Node3D] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if player != null:
		player_start_position = player.global_position
		player_start_rotation = player.global_rotation
		print("PLAYER START SAVED")
	else:
		push_warning("Assign the Player in the Inspector!")

	for cube in cubes:
		if is_instance_valid(cube):
			cube_start_positions.append(cube.global_position)
			cube_start_rotations.append(cube.global_rotation)

	print("SAVED CUBES: ", cubes.size())


func _on_body_entered(body: Node3D) -> void:
	if resetting.has(body):
		return

	if body == player:
		reset_player()
		return

	var cube_index := cubes.find(body as RigidBody3D)

	if cube_index != -1:
		reset_cube(body as RigidBody3D, cube_index)


func reset_player() -> void:
	if not is_instance_valid(player):
		return

	resetting.append(player)

	player.velocity = Vector3.ZERO
	player.global_position = player_start_position
	player.global_rotation = player_start_rotation

	await get_tree().physics_frame
	resetting.erase(player)

	print("PLAYER RESET")


func reset_cube(cube: RigidBody3D, index: int) -> void:
	resetting.append(cube)

	cube.freeze = true
	cube.linear_velocity = Vector3.ZERO
	cube.angular_velocity = Vector3.ZERO

	cube.global_position = cube_start_positions[index]
	cube.global_rotation = cube_start_rotations[index]

	cube.sleeping = false
	cube.freeze = false

	await get_tree().physics_frame
	resetting.erase(cube)

	print("CUBE RESET: ", cube.name)
