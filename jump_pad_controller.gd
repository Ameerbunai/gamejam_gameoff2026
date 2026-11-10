
extends Node3D

@export var jump_pads: Array[Area3D] = []
@export var move_speed: float = 2.0
@export var movement_axis: Vector3 = Vector3.RIGHT

# Angry system settings
@export var anger_check_interval: float = 10.0
@export var anger_chance: float = 0.1
@export var warning_shake_duration: float = 1.0
@export var angry_duration: float = 6.0
@export var cooldown_duration: float = 1.0
@export var shake_strength: float = 0.08
@export var angry_direction_change_time: float = 0.7

# Highlight colors
@export var normal_color: Color = Color(0.2, 0.8, 1.0)
@export var angry_color: Color = Color(1.0, 0.05, 0.05)

var active_pad_index: int = 0
var move_direction: float = 0.0
var vertical_direction: float = 0.0

# Angry system state
var anger_system_started: bool = false
var anger_check_timer: float = 0.0

var is_shaking: bool = false
var is_angry: bool = false
var is_cooling_down: bool = false

var effect_pad: Area3D = null
var shake_origin: Vector3

var shake_timer: float = 0.0
var angry_timer: float = 0.0
var cooldown_timer: float = 0.0
var angry_direction_timer: float = 0.0

var angry_direction: Vector3 = Vector3.ZERO
var current_highlight_color: Color


func _ready() -> void:
	randomize()
	current_highlight_color = normal_color
	update_highlight()


func _process(delta: float) -> void:
	update_angry_system(delta)
	update_highlight_color()

	if jump_pads.is_empty():
		return

	if active_pad_index >= jump_pads.size():
		return

	var pad := jump_pads[active_pad_index]

	if not is_instance_valid(pad):
		return

	if is_shaking or is_angry or is_cooling_down:
		return

	var direction := (
		movement_axis.normalized() * move_direction
		+ Vector3.UP * vertical_direction
	)

	if direction.length() > 0.0:
		pad.global_position += direction.normalized() * move_speed * delta


# =========================
# NORMAL CONTROLS
# =========================

func set_move_direction(direction: float) -> void:
	move_direction = clampf(direction, -1.0, 1.0)

	if move_direction != 0.0:
		start_anger_checks()


func set_vertical_direction(direction: float) -> void:
	vertical_direction = clampf(direction, -1.0, 1.0)

	if vertical_direction != 0.0:
		start_anger_checks()


func stop_moving() -> void:
	move_direction = 0.0
	vertical_direction = 0.0


func switch_pad() -> void:
	if jump_pads.is_empty():
		return

	stop_moving()

	active_pad_index += 1

	if active_pad_index >= jump_pads.size():
		active_pad_index = 0

	print("ACTIVE JUMP PAD: ", active_pad_index + 1)

	update_highlight()


# =========================
# ANGRY SYSTEM
# =========================

func start_anger_checks() -> void:
	if anger_system_started:
		return

	anger_system_started = true
	anger_check_timer = 0.0

	print("ANGER SYSTEM STARTED")


func update_angry_system(delta: float) -> void:

	# Check every 10 seconds after the first movement.
	if anger_system_started and not is_shaking and not is_angry and not is_cooling_down:
		anger_check_timer += delta

		if anger_check_timer >= anger_check_interval:
			anger_check_timer = 0.0

			if randf() < anger_chance:
				start_warning_shake()

	# Warning shake.
	if is_shaking:
		if not is_instance_valid(effect_pad):
			is_shaking = false
			return

		shake_timer += delta

		effect_pad.global_position = (
			shake_origin
			+ Vector3(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)
		)

		if shake_timer >= warning_shake_duration:
			effect_pad.global_position = shake_origin

			is_shaking = false
			is_angry = true

			angry_timer = 0.0
			angry_direction_timer = 0.0

			randomize_angry_direction()

			print("JUMP PAD ANGRY!")

	# Random angry movement.
	elif is_angry:
		if not is_instance_valid(effect_pad):
			is_angry = false
			return

		angry_timer += delta
		angry_direction_timer += delta

		if angry_direction_timer >= angry_direction_change_time:
			angry_direction_timer = 0.0
			randomize_angry_direction()

		effect_pad.global_position += (
			angry_direction * move_speed * delta
		)

		if angry_timer >= angry_duration:
			is_angry = false
			is_cooling_down = true
			cooldown_timer = 0.0

			print("JUMP PAD CALMING DOWN!")

	# Return to normal.
	elif is_cooling_down:
		cooldown_timer += delta

		if cooldown_timer >= cooldown_duration:
			is_cooling_down = false
			effect_pad = null

			print("JUMP PAD CALMED DOWN!")


func start_warning_shake() -> void:
	if jump_pads.is_empty():
		return

	if active_pad_index >= jump_pads.size():
		return

	effect_pad = jump_pads[active_pad_index]

	if not is_instance_valid(effect_pad):
		return

	is_shaking = true
	shake_timer = 0.0
	shake_origin = effect_pad.global_position

	print("JUMP PAD IS SHAKING!")


func randomize_angry_direction() -> void:
	var random_direction := Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

	if random_direction.length() == 0.0:
		random_direction = Vector2.RIGHT

	angry_direction = (
		movement_axis.normalized() * random_direction.x
		+ Vector3.UP * random_direction.y
	).normalized()


# =========================
# COLOR TRANSITIONS
# =========================

func update_highlight_color() -> void:
	if is_shaking:
		var progress := clampf(
			shake_timer / warning_shake_duration,
			0.0,
			1.0
		)

		current_highlight_color = normal_color.lerp(
			angry_color,
			progress
		)

	elif is_angry:
		current_highlight_color = angry_color

	elif is_cooling_down:
		var progress := clampf(
			cooldown_timer / cooldown_duration,
			0.0,
			1.0
		)

		current_highlight_color = angry_color.lerp(
			normal_color,
			progress
		)

	else:
		current_highlight_color = normal_color

	apply_highlight_color(current_highlight_color)


func apply_highlight_color(color: Color) -> void:
	if jump_pads.is_empty():
		return

	if active_pad_index >= jump_pads.size():
		return

	var pad := jump_pads[active_pad_index]

	if not is_instance_valid(pad):
		return

	var meshes: Array[MeshInstance3D] = []
	find_meshes(pad, meshes)

	for mesh in meshes:
		var material := mesh.material_overlay as StandardMaterial3D

		if material == null:
			continue

		material.albedo_color = color
		material.emission = color


# =========================
# HIGHLIGHT SYSTEM
# =========================

func update_highlight() -> void:
	for i in range(jump_pads.size()):
		var pad := jump_pads[i]

		if not is_instance_valid(pad):
			continue

		var meshes: Array[MeshInstance3D] = []
		find_meshes(pad, meshes)

		for mesh in meshes:
			if i == active_pad_index:
				mesh.material_overlay = create_highlight_material()
			else:
				mesh.material_overlay = null


func find_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			result.append(child)

		find_meshes(child, result)


func create_highlight_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()

	material.albedo_color = current_highlight_color
	material.emission_enabled = true
	material.emission = current_highlight_color
	material.emission_energy_multiplier = 2.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	return material
