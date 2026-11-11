extends Area3D


@export var video_player: VideoStreamPlayer
@export var next_level: PackedScene

var transition_started: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if is_instance_valid(video_player):
		video_player.finished.connect(_on_video_finished)
		video_player.visible = false


func _on_body_entered(body: Node3D) -> void:
	if transition_started:
		return

	if not body is CharacterBody3D:
		return

	transition_started = true
	monitoring = false

	print("PLAYER ENTERED EXIT!")

	if not is_instance_valid(video_player):
		push_error("VIDEO PLAYER NOT ASSIGNED!")
		return

	video_player.visible = true
	video_player.play()


func _on_video_finished() -> void:
	print("CUTSCENE FINISHED!")

	if next_level == null:
		push_error("NEXT LEVEL NOT ASSIGNED!")
		return

	get_tree().change_scene_to_packed(next_level)
