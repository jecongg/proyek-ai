extends Node2D

func _ready():
	# 1. Ambil ukuran layar HP pemain saat ini
	var screen_size = get_viewport_rect().size
	
	# 2. Pindahkan posisi Board tepat ke titik tengah layar
	$Board.position = screen_size / 2
