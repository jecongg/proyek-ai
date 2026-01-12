extends Control

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://game_panel.tscn")

func _on_exit_button_pressed():
	get_tree().quit()


func _ready():
	$CenterContainer/MenuContainer/DepthSlider.value = GlobalSettings.ai_depth
	
	update_depth_text(GlobalSettings.ai_depth)
	SoundManager.play_music("menu")

func _on_depth_slider_value_changed(value: float) -> void:
	GlobalSettings.ai_depth = int(value)
	
	update_depth_text(value)

func update_depth_text(val: float):
	var level_name = ""
	var v = int(val)
	
	if v <= 2: level_name = " (Easy)"
	elif v <= 4: level_name = " (Normal)"
	elif v <= 6: level_name = " (Hard)"
	elif v <= 8: level_name = " (Expert)"
	else: level_name = " (MASTER)" 
	
	$CenterContainer/MenuContainer/DepthLabel.text = "AI Difficulty: " + str(v) + level_name
