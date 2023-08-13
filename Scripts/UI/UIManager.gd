extends CanvasLayer


func _ready():
	GameManager.pause_menu = $PauseMenu
	GameManager.win_screen = $WinScreen
	GameManager.score_label = $WinScreen/Label
	
	GameManager.gained_coins.connect(update_coin_display)

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		GameManager.pause_play()
		get_tree().paused = GameManager.paused

func update_coin_display():
	$CoinDisplay.text = str(GameManager.coins)

func _on_resume_pressed():
	GameManager.resume()

func _on_restart_pressed():
	GameManager.restart()

func _on_world_map_pressed():
	GameManager.load_world()

func _on_quit_pressed():
	GameManager.quit()

func _on_finnish_level_pressed():
	GameManager.load_world()
