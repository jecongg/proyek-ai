extends CharacterData
class_name LeaderData

func _init():
	id = "LEADER"
	display_name = "Leader"
	description = "Raja yang harus dilindungi."
	
	# Kolom ke-berapa gambar Leader di spritesheet kamu?
	# Misal Leader ada di urutan kedua (setelah Acrobat), isi 1.
	sprite_column = 1 # Cek gambar spritesheetmu, kolom ke berapa?
	
	cost = 0 # Leader biasanya gratis/awal

func get_valid_moves(board_state: Dictionary, current_pos: Vector2i) -> Array:
	var moves = []
	
	# GUNAKAN ARAH SKEWED HASIL RISET KAMU
	# (Jangan pakai Vector2i(1,0) yang standar matematika)
	var valid_directions = [
		Vector2i(0, -1),  # Atas Kiri
		Vector2i(1, -2),  # Atas Kanan
		Vector2i(1, -1),  # Kanan
		Vector2i(0, 1),   # Bawah Kanan
		Vector2i(-1, 2),  # Bawah Kiri
		Vector2i(-1, 1)   # Kiri
	]
	
	for dir in valid_directions:
		# Leader bergerak 1 langkah
		var target_pos = current_pos + dir
		
		# Validasi sederhana:
		# Nanti di GridManager kita cek apakah target_pos ada di valid_tiles
		moves.append(target_pos)
			
	return moves
