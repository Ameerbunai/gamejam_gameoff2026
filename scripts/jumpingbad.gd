extends Area3D

@export var player_launch_velocity: float = 12.0
@export var cube_launch_velocity: float = 12.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	print("JUMP PAD READY")

func _on_body_entered(body: Node3D) -> void:
	print("TOUCHED BY: ", body.name)

	if body is CharacterBody3D:
		body.velocity.y = player_launch_velocity
		print("PLAYER LAUNCHED!")

	elif body is RigidBody3D:
		body.sleeping = false
		body.linear_velocity.y = cube_launch_velocity
		print("CUBE LAUNCHED!")
