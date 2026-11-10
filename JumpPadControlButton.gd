extends StaticBody3D

enum ButtonAction {
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_UP,
	MOVE_DOWN,
	SWITCH_PAD
}

@export var action: ButtonAction = ButtonAction.MOVE_LEFT
@export var required_mass: float = 2.0
@export var mass_tolerance: float = 0.1
@export var controller: Node3D

@onready var detection_area: Area3D = $DetectionArea

var pressed_body: RigidBody3D = null


func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	print("BUTTON READY: ", name)


func _physics_process(_delta: float) -> void:
	if pressed_body != null:
		if not is_instance_valid(pressed_body):
			_release_button()
			return

		if pressed_body.get("held") == true:
			_release_button()

		return

	for body in detection_area.get_overlapping_bodies():
		if body is RigidBody3D:
			_try_activate(body)

			if pressed_body != null:
				break


func _on_detection_area_body_entered(body: Node3D) -> void:
	_try_activate(body)


func _try_activate(body: Node3D) -> void:
	if not body is RigidBody3D:
		return

	var block := body as RigidBody3D

	if block.get("held") == true:
		return

	if absf(block.mass - required_mass) > mass_tolerance:
		return

	if pressed_body != null:
		return

	pressed_body = block

	print("BUTTON ACTIVATED: ", name)

	if not is_instance_valid(controller):
		push_warning("CONTROLLER NOT ASSIGNED: " + name)
		return

	match action:
		ButtonAction.MOVE_LEFT:
			controller.call("set_move_direction", -1.0)

		ButtonAction.MOVE_RIGHT:
			controller.call("set_move_direction", 1.0)

		ButtonAction.MOVE_UP:
			controller.call("set_vertical_direction", 1.0)

		ButtonAction.MOVE_DOWN:
			controller.call("set_vertical_direction", -1.0)

		ButtonAction.SWITCH_PAD:
			controller.call("switch_pad")


func _on_detection_area_body_exited(body: Node3D) -> void:
	if body != pressed_body:
		return

	_release_button()


func _release_button() -> void:
	pressed_body = null

	print("BUTTON RELEASED: ", name)

	if not is_instance_valid(controller):
		return

	match action:
		ButtonAction.MOVE_LEFT, ButtonAction.MOVE_RIGHT:
			controller.call("set_move_direction", 0.0)

		ButtonAction.MOVE_UP, ButtonAction.MOVE_DOWN:
			controller.call("set_vertical_direction", 0.0)
