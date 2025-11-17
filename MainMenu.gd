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
