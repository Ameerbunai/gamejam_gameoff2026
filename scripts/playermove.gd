
extends CharacterBody3D

@export var speed: float = 7.0
@export var jump_velocity: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var pickup_distance: float = 4.0
@export var hold_distance: float = 2.5
@export var hold_strength: float = 10.0
@export var shake_strength: float = 0.04
@export var shake_duration: float = 0.12

var shake_timer: float = 0.0
var camera_original_position: Vector3
# Movement launcher
@export var boost_cooldown: float = 0.8
@export var boost_duration: float = 0.45
@export var boost_fov: float = 95.0
@export var fov_animation_time: float = 0.25

var objects_in_portal: Array[RigidBody3D] = []
var gravity: float = 9.8
var held_block: RigidBody3D = null
var selected_block: RigidBody3D = null

var boost_cooldown_timer: float = 0.0
var boost_active_timer: float = 0.0
var normal_fov: float = 75.0
var fov_tween: Tween

@onready var camera: Camera3D = $Camera3D
@onready var interact_ray: RayCast3D = $Camera3D/RayCast3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	normal_fov = camera.fov
	camera_original_position = camera.position


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if held_block != null:
			if is_instance_valid(held_block):
				held_block.drop_block()
			held_block = null
		else:
			try_pickup_block()

	# Left-click: use the held gun or click world buttons.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			if held_block != null and is_instance_valid(held_block):
				if held_block.has_method("shoot"):
					held_block.shoot(camera)
					return

			print("CLICK RECEIVED")

			var from: Vector3 = camera.global_position
			var to: Vector3 = from - camera.global_basis.z * 5.0

			var query := PhysicsRayQueryParameters3D.create(from, to)
			query.exclude = [get_rid()]

			var result = get_world_3d().direct_space_state.intersect_ray(query)

			if result.is_empty():
				print("RAY HIT NOTHING")
				return

			var target = result["collider"]
			print("HIT: ", target.name)

			if target.name == "PastButton":
				shift_object("past")

			elif target.name == "FutureButton":
				shift_object("future")

			elif target.name == "MassButton":
				target.activate()

	# Mouse look
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(
				camera.rotation.x,
				deg_to_rad(-89.0),
				deg_to_rad(89.0)
			)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	boost_cooldown_timer = maxf(0.0, boost_cooldown_timer - delta)
	boost_active_timer = maxf(0.0, boost_active_timer - delta)

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	var direction := (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	var acceleration := 20.0
	var deceleration := 25.0

	# Preserve momentum while the launcher boost is active.
	if boost_active_timer > 0.0:
		acceleration = 5.0
		deceleration = 3.5

	if direction != Vector3.ZERO:
		velocity.x = move_toward(
			velocity.x, direction.x * speed, acceleration * delta
		)
		velocity.z = move_toward(
			velocity.z, direction.z * speed, acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x, 0.0, deceleration * delta
		)
		velocity.z = move_toward(
			velocity.z, 0.0, deceleration * delta
		)

	move_and_slide()
	move_held_block()


# Called by the gun.
func apply_movement_boost(direction: Vector3, strength: float) -> void:
	play_camera_shake()
	if boost_cooldown_timer > 0.0:
		return

	direction = direction.normalized()

	velocity += direction * strength

	boost_cooldown_timer = boost_cooldown
	boost_active_timer = boost_duration

	animate_boost_fov()

	print("RECOIL: ", direction)


func animate_boost_fov() -> void:
	if fov_tween != null and fov_tween.is_running():
		fov_tween.kill()

	fov_tween = create_tween()

	fov_tween.tween_property(
		camera,
		"fov",
		boost_fov,
		0.10
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	fov_tween.tween_property(
		camera,
		"fov",
		normal_fov,
		fov_animation_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func try_pickup_block() -> void:
	var from: Vector3 = camera.global_position
	var to: Vector3 = from - camera.global_basis.z * pickup_distance

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		print("NOTHING HIT")
		return

	var target = result["collider"]

	if target is RigidBody3D and target.has_method("try_pickup"):
		target.try_pickup(camera, self)

		if target.held:
			held_block = target
			selected_block = target
			print("BLOCK SELECTED")
	else:
		print("NOT A PICKUP BLOCK")


func move_held_block() -> void:
	if held_block == null:
		return

	if not is_instance_valid(held_block):
		held_block = null


func shift_object(direction: String) -> void:
	var target: RigidBody3D = null

	if is_instance_valid(held_block):
		target = held_block
	elif is_instance_valid(selected_block):
		target = selected_block

	if target == null:
		print("NO BLOCK SELECTED")
		return

	if not objects_in_portal.has(target):
		print("BLOCK MUST BE INSIDE THE PORTAL!")
		return

	if direction == "past":
		target.past()
	elif direction == "future":
		target.future()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == self:
		Global.is_in_portal = true
		print("PLAYER ENTERED PORTAL")
		return

	if body is RigidBody3D:
		if not objects_in_portal.has(body):
			objects_in_portal.append(body)
			print("OBJECT ENTERED PORTAL: ", body.name)


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == self:
		Global.is_in_portal = false
		print("PLAYER LEFT PORTAL")
		return

	if body is RigidBody3D:
		objects_in_portal.erase(body)
		print("OBJECT LEFT PORTAL: ", body.name)
func play_camera_shake() -> void:
	shake_timer = shake_duration
	
func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta

		var strength := shake_strength * (shake_timer / shake_duration)

		camera.position = camera_original_position + Vector3(
			randf_range(-strength, strength),
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
	else:
		camera.position = camera_original_position
