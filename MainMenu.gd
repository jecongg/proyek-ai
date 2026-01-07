extends Control

# Fungsi ini akan dipanggil ketika tombol Play ditekan.
func _on_play_button_pressed():
	# get_tree() adalah cara untuk mengakses scene tree utama game.
	# change_scene_to_file() akan membuang scene saat ini (menu)
	# dan memuat scene baru dari file yang kita tentukan.
	# Pastikan path file ini benar sesuai dengan lokasi scene game Anda.
	get_tree().change_scene_to_file("res://game_panel.tscn")

# Fungsi ini akan dipanggil ketika tombol Exit ditekan.
func _on_exit_button_pressed():
	# Perintah ini akan menutup aplikasi game dengan aman.
	get_tree().quit()


func _ready():
	# 1. Pastikan Slider berada di angka yang tersimpan saat ini
	$CenterContainer/MenuContainer/DepthSlider.value = GlobalSettings.ai_depth
	
	# 2. Update Label saat pertama kali dibuka
	update_depth_text(GlobalSettings.ai_depth)
	SoundManager.play_music("menu")

# --- FUNGSI SIGNAL SLIDER ---
func _on_depth_slider_value_changed(value: float) -> void:
	# Simpan nilai slider ke GlobalSettings (Singleton)
	GlobalSettings.ai_depth = int(value)
	
	# Update tulisan di Label agar pemain tahu levelnya
	update_depth_text(value)

func update_depth_text(val: float):
	var level_name = ""
	var v = int(val)
	
	if v <= 2: level_name = " (Easy)"
	elif v <= 4: level_name = " (Normal)"
	elif v <= 6: level_name = " (Hard)"
	elif v <= 8: level_name = " (Expert)"
	else: level_name = " (MASTER)" # Untuk depth 9-10
	
	$CenterContainer/MenuContainer/DepthLabel.text = "AI Difficulty: " + str(v) + level_name
