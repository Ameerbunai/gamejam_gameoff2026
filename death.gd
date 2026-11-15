
extends Area3D

@export var player: CharacterBody3D
@export var damage_per_second: float = 20.0

var damaging: bool = false
var damage_timer: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	print("LAVA DAMAGE AREA READY")


func _process(delta: float) -> void:
	if not damaging or not is_instance_valid(player):
		return

	damage_timer += delta

	if damage_timer >= 1.0:
		damage_timer -= 1.0
		player.take_damage(damage_per_second)


func _on_body_entered(body: Node3D) -> void:
	if body != player:
		return

	damaging = true
	print("PLAYER TOUCHING LAVA!")


func _on_body_exited(body: Node3D) -> void:
	if body != player:
		return

	damaging = false
	damage_timer = 0.0
	print("PLAYER LEFT LAVA")
