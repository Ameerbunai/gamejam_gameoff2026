
extends Node

@export var damage_overlay: ColorRect

@export var flash_alpha: float = 0.4
@export var fade_duration: float = 0.4

var damage_tween: Tween


func _ready() -> void:
	if damage_overlay == null:
		push_error("DAMAGE OVERLAY NOT ASSIGNED!")
		return

	damage_overlay.color = Color(1, 0, 0, 0)
	print("DAMAGE EFFECT READY")


func play_damage_effect() -> void:
	if not is_instance_valid(damage_overlay):
		return

	if damage_tween and damage_tween.is_running():
		damage_tween.kill()

	damage_overlay.color = Color(1, 0, 0, flash_alpha)

	damage_tween = create_tween()
	damage_tween.tween_property(
		damage_overlay,
		"color:a",
		0.0,
		fade_duration
	)
