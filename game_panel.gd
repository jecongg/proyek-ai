extends Node2D

# Ambil referensi ke benda-benda penting
@onready var board = $Board
@onready var game_manager = $GameManager
@onready var skip_button = $UILayer/BtnSkip # Pastikan path-nya sesuai struktur scene kamu

func _ready():
	# --- 1. LOGIKA POSISI (YANG LAMA) ---
	var screen_size = get_viewport_rect().size
	board.position = screen_size / 2
	
	# --- 2. LOGIKA TOMBOL (BARU) ---
	# Hubungkan sinyal "pressed" (diklik) ke fungsi di bawah
	skip_button.pressed.connect(_on_skip_pressed)

# Fungsi ini jalan saat tombol diklik
func _on_skip_pressed():
	# Tambahkan Cek GAME_OVER
	if game_manager.current_state == game_manager.State.GAME_OVER:
		return

	if game_manager.current_state == game_manager.State.ACTION_PHASE:
		game_manager.skip_action_phase()
