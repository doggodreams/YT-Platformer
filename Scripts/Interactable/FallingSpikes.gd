extends Node2D

var speed = 200.0
var current_speed = 0.0

@onready var spawn_pos = global_position

func _physics_process(delta):
	position.y += current_speed * delta

func _on_hitbox_area_entered(area):
	if area.get_parent() is Player:
		area.get_parent().take_damage(1)

func _on_player_detect_area_entered(area):
	if area.get_parent() is Player:
		$AnimationPlayer.play("Shake")

func fall():
	current_speed = speed
	await get_tree().create_timer(5).timeout
	position = spawn_pos
	current_speed = 0
