
extends AnimatableBody3D

@export var animation_player: AnimationPlayer
@export var door_collision: CollisionShape3D
@export var open_animation: StringName = &"open_anmtons"

var is_open: bool = false
var is_closing: bool = false


func _ready() -> void:
	print("DOOR READY")

	if animation_player == null:
		print("ERROR: ANIMATION PLAYER IS NULL")
		return

	print("ANIMATIONS: ", animation_player.get_animation_list())
	print("DOOR COLLISION: ", door_collision)

	animation_player.animation_finished.connect(_on_animation_finished)
	if animation_player == null:
		push_error("AnimationPlayer not assigned!")
		return

	if door_collision == null:
		push_error("Door Collision not assigned!")
		return

	animation_player.stop()
	door_collision.disabled = false

	animation_player.animation_finished.connect(_on_animation_finished)

	print("DOOR READY")


func open_door() -> void:
	print("OPEN DOOR CALLED")

	if is_open or animation_player == null:
		return

	is_open = true
	door_collision.set_deferred("disabled", true)
	animation_player.play(open_animation)

	print("PLAYING: ", open_animation)
	if is_open or animation_player == null:
		return

	is_open = true
	is_closing = false

	door_collision.set_deferred("disabled", true)

	animation_player.play(open_animation)
	print("DOOR OPENING")


func close_door() -> void:
	if not is_open or animation_player == null:
		return

	is_open = false
	is_closing = true

	animation_player.play_backwards(open_animation)
	print("DOOR CLOSING")


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == open_animation and is_closing:
		door_collision.set_deferred("disabled", false)
		is_closing = false
		print("DOOR CLOSED - COLLISION ENABLED")
