# SoundManager.gd
extends Node

var music_player : AudioStreamPlayer

var bgm_menu = preload("res://assets/audio/Epic & Heroic Orchestral Music Compilation  Cinematic Royalty-Free Soundtracks.mp3")
var bgm_game = preload("res://assets/audio/War Epic Music Collection! Prepare for Battle Military Orchestral Megamix!.mp3") 

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Master"
	
	music_player.finished.connect(_on_music_finished)

func play_music(type: String):
	var target_stream : AudioStream
	
	if type == "menu":
		target_stream = bgm_menu
	else:
		target_stream = bgm_game
		
	if music_player.playing and music_player.stream == target_stream:
		return
		
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -40.0, 0.8) 
		tween.finished.connect(func(): _start_new_track(target_stream))
	else:
		_start_new_track(target_stream)

func _start_new_track(new_stream: AudioStream):
	music_player.stream = new_stream
	music_player.volume_db = -40.0 
	music_player.play()
	
	var tween_in = create_tween()
	tween_in.tween_property(music_player, "volume_db", -15.0, 0.8)

func _on_music_finished():
	music_player.play()

func set_volume(value_db: float):
	music_player.volume_db = value_db
