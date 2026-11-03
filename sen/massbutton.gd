
extends StaticBody3D

@export var required_mass: float = 5.0
@export var mass_tolerance: float = 0.1
@export var door: Node3D

@onready var detection_area: Area3D = $DetectionArea

var pressed_body: RigidBody3D = null


func _ready() -> void:
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body is RigidBody3D:
		return

	var block := body as RigidBody3D

	if abs(block.mass - required_mass) <= mass_tolerance:
		pressed_body = block

		print("CORRECT MASS! BUTTON PRESSED")

		if door and door.has_method("open_door"):
			door.call("open_door")
	else:
		print("WRONG MASS: ", block.mass)
		print("REQUIRED MASS: ", required_mass)


func _on_body_exited(body: Node3D) -> void:
	if body != pressed_body:
		return

	pressed_body = null

	print("BUTTON RELEASED")

	if door and door.has_method("close_door"):
		door.call("close_door")
