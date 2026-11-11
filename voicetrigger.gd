
extends Area3D

@export var voice_audio: AudioStream
@export_multiline var subtitle_text: String = ""
@export var play_once: bool = true

var has_played: bool = false

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return

	if play_once and has_played:
		return

	if audio_player.playing:
		return

	if voice_audio == null:
		push_warning("NO VOICE AUDIO ASSIGNED: " + name)
		return

	has_played = true

	var subtitle_manager = get_tree().get_first_node_in_group("SubtitleManager")

	if subtitle_manager:
		subtitle_manager.show_subtitle(subtitle_text)

	audio_player.stream = voice_audio
	audio_player.play()

	await audio_player.finished

	if subtitle_manager:
		subtitle_manager.hide_subtitle()
