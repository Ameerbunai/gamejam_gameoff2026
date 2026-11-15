
extends Control

@onready var main_menu = $Background/Menu
@onready var level_picker = $Background/levelpicker


func _ready() -> void:
	level_picker.hide()
	main_menu.show()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://sen/level_1.tscn")


func _on_level_selectbutton_pressed() -> void:
	main_menu.hide()
	level_picker.show()


func _on_quitbutton_pressed() -> void:
	get_tree().quit()


func _on_level_1_pressed() -> void:
	get_tree().change_scene_to_file("res://sen/level_1.tscn")


func _on_level_2_pressed() -> void:
	get_tree().change_scene_to_file("res://level_2.tscn")


func _on_level_3_pressed() -> void:
	get_tree().change_scene_to_file("res://level_3.tscn")


func _on_level_4_pressed() -> void:
	get_tree().change_scene_to_file("res://level_4.tscn")


func _on_backbutton_pressed() -> void:
	level_picker.hide()
	main_menu.show()
