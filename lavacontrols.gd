extends Node3D

@export var lava: AnimatableBody3D
@export var voice_trigger: Area3D
@export var rise_speed: float = 0.5

@onready var lava_sound: AudioStreamPlayer3D = $LavaSound

var start_position: Vector3
var lava_started: bool = false


func _ready() -> void:
	set_physics_process(false)

	if lava == null:
		push_error("LAVA NOT ASSIGNED!")
		return

	if voice_trigger == null:
		push_error("VOICE TRIGGER NOT ASSIGNED!")
		return

	start_position = lava.global_position
	voice_trigger.dialogue_finished.connect(_on_voice_finished)

	lava_sound.stop()

	print("LAVA SYSTEM READY - WAITING FOR VOICE")


func _on_voice_finished() -> void:
	if lava_started:
		return

	await get_tree().create_timer(1.0).timeout

	lava_started = true
	set_physics_process(true)

	lava_sound.play()

	print("LAVA STARTED!")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(lava):
		return

	lava.global_position.y += rise_speed * delta
