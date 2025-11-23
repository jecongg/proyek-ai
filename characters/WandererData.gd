# WandererData.gd
extends CharacterData
class_name WandererData

func _init():
	id = "WANDERER"
	display_name = "Wanderer"
	description = "Terbang ke petak manapun yang aman dari musuh."
	sprite_column = 7
	card_x = 8
	card_y = 0
	cost = 1

func get_valid_moves(board_state: Dictionary, current_pos: Vector2i) -> Array:
	var moves = []
	var directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	# Kita butuh akses ke Valid Tiles (Semua kotak di papan)
	# Karena ini Resource, kita tidak bisa akses GridManager langsung.
	# Solusi: Kirim 'valid_tiles' via parameter nanti, atau hardcode logic area.
	
	# CONTOH LOGIC:
	# 1. Loop semua tile di board_state (atau valid_tiles yang dipassing)
	# 2. Cek apakah tile itu kosong?
	# 3. Cek apakah tetangga tile itu ada musuh?
	
	# (Implementasi detail butuh akses data GridManager.valid_tiles)
	return moves
