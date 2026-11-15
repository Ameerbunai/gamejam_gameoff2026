
extends Control

@export var crosshair_color: Color = Color.WHITE
@export var gap: float = 5.0
@export var line_length: float = 10.0
@export var thickness: float = 3.0

@onready var top_line: ColorRect = $Top
@onready var bottom_line: ColorRect = $bottom
@onready var left_line: ColorRect = $left
@onready var right_line: ColorRect = $right


func _ready() -> void:
	resized.connect(update_crosshair)
	update_crosshair()


func update_crosshair() -> void:
	var center := size / 2.0

	top_line.position = center + Vector2(-thickness / 2.0, -gap - line_length)
	top_line.size = Vector2(thickness, line_length)

	bottom_line.position = center + Vector2(-thickness / 2.0, gap)
	bottom_line.size = Vector2(thickness, line_length)

	left_line.position = center + Vector2(-gap - line_length, -thickness / 2.0)
	left_line.size = Vector2(line_length, thickness)

	right_line.position = center + Vector2(gap, -thickness / 2.0)
	right_line.size = Vector2(line_length, thickness)

	for line in [top_line, bottom_line, left_line, right_line]:
		line.color = crosshair_color
