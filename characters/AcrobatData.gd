extends CharacterData
class_name AcrobatData

func _init():
	id = "ACROBAT"
	display_name = "The Acrobat"
	description = "Melompati unit lain sejauh 2 langkah."
	sprite_column = 5
	cost = 2

func get_valid_moves(board_state: Dictionary, current_pos: Vector2i) -> Array:
	var moves = []
	
	# PENTING: Ambil arah dari GridManager yang sudah dikoreksi
	# Jangan ketik manual Vector2i lagi
	#var directions = preload("res://game_panel.gd").GridManager_DIRECTIONS 
	# ^ Cara di atas agak ribet karena GridManager nempel di node. 
	# LEBIH BAIK KITA COPY ARRAYNYA KE SINI:
	const valid_directions = [
		Vector2i(0, -1),  # Atas Kiri
		Vector2i(1, -2),  # Atas Kanan
		Vector2i(1, -1),  # Kanan
		Vector2i(0, 1),   # Bawah Kanan
		Vector2i(-1, 2),  # Bawah Kiri
		Vector2i(-1, 1)   # Kiri
	]
	
	#var valid_directions = [
		#Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		#Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	#]
	
	for dir in valid_directions:
		# Lompat 2 langkah (kali 2)
		var target_pos = current_pos + (dir * 2)
		
		# Logic tambahan: Acrobat biasanya harus melompati SESEORANG.
		# Kalau di game aslinya boleh lompat di ruang kosong, biarkan code ini.
		# Kalau wajib ada orang yang dilompati:
		# var mid_pos = current_pos + dir
		# if board_state.has(mid_pos): moves.append(target_pos)
		
		moves.append(target_pos)
			
	return moves
