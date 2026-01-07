# SoundManager.gd
extends Node

var music_player : AudioStreamPlayer

# 1. Masukkan file musik kamu di sini (Pastikan PATH foldernya benar!)
# Lagu 1: Untuk Menu
var bgm_menu = preload("res://assets/audio/Epic & Heroic Orchestral Music Compilation  Cinematic Royalty-Free Soundtracks.mp3")
# Lagu 2: Untuk Game (Ganti "game_bgm.mp3" dengan nama file musikmu sendiri)
var bgm_game = preload("res://assets/audio/War Epic Music Collection! Prepare for Battle Military Orchestral Megamix!.mp3") 

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Master"
	
	# Menghubungkan sinyal looping
	music_player.finished.connect(_on_music_finished)

# 2. Fungsi baru untuk pindah lagu secara pintar
func play_music(type: String):
	var target_stream : AudioStream
	
	if type == "menu":
		target_stream = bgm_menu
	else:
		target_stream = bgm_game
		
	# Cek 1: Jika musik yang diminta SUDAH sedang dimainkan, jangan restart
	if music_player.playing and music_player.stream == target_stream:
		return
		
	# Cek 2: Jika ada musik lain sedang main, lakukan transisi halus (Fade)
	if music_player.playing:
		var tween = create_tween()
		# Kecilkan suara lagu lama (Fade Out)
		tween.tween_property(music_player, "volume_db", -40.0, 0.8) 
		# Setelah suara habis, baru ganti lagu
		tween.finished.connect(func(): _start_new_track(target_stream))
	else:
		# Jika belum ada musik main, langsung mulai
		_start_new_track(target_stream)

# Helper untuk memulai lagu baru dengan Fade In
func _start_new_track(new_stream: AudioStream):
	music_player.stream = new_stream
	music_player.volume_db = -40.0 # Mulai dari sunyi
	music_player.play()
	
	# Besarkan suara lagu baru (Fade In)
	var tween_in = create_tween()
	tween_in.tween_property(music_player, "volume_db", -15.0, 0.8)

func _on_music_finished():
	# Memastikan lagu berputar ulang (Loop)
	music_player.play()

func set_volume(value_db: float):
	music_player.volume_db = value_db
