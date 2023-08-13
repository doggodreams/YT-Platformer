extends Node2D


func _ready():
	$AnimationPlayer.play("Idle")

func _on_area_2d_area_entered(area):
	if area.get_parent() is Player:
		GameManager.gain_coins(1)
		GameManager.score += 50
		queue_free()
