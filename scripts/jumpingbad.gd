
extends Area3D

@export var player_launch_velocity: float = 12.0
@export var cube_launch_velocity: float = 12.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	print("JUMP PAD READY")


func _on_body_entered(body: Node3D) -> void:
	print("TOUCHED BY: ", body.name)

	# Follow the pad's actual rotated UP direction.
	var launch_direction: Vector3 = global_basis.y.normalized()

	if body is CharacterBody3D:
		body.velocity = launch_direction * player_launch_velocity
		print("PLAYER LAUNCHED: ", launch_direction)

	elif body is RigidBody3D:
		body.sleeping = false
		body.linear_velocity = launch_direction * cube_launch_velocity
		print("CUBE LAUNCHED: ", launch_direction)


func _on_detection_area_body_exited(body):
	pass # Replace with function body.
