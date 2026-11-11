
extends CanvasLayer

@onready var subtitle_label: Label = $Label



func _ready() -> void:
	subtitle_label.visible = false

func show_subtitle(message: String) -> void:
	subtitle_label.text = message
	subtitle_label.visible = true

func hide_subtitle() -> void:
	subtitle_label.visible = false
