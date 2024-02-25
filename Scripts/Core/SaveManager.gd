extends Node

var save_path = "res://Saves/"
var save_name = "save1.tres"
var save_data = SaveData.new()

func load_game():
	save_data = ResourceLoader.load(save_path + save_name).duplicate(true)
	LevelData.level_dic = save_data.level_dic

func save_game():
	save_data.level_dic = LevelData.level_dic
	ResourceSaver.save(save_data, save_path + save_name)
