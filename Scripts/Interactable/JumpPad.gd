extends Node2D

@export var force = -550.0


func _on_area_2d_area_entered(area):
	if area.get_parent() is Player:
		area.get_parent().velocity.y = force
