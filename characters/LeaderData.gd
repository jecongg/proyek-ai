extends CharacterData
class_name LeaderData

func _init():
	id = "LEADER"
	display_name = "Leader"
	description = "Raja yang harus dilindungi."
	
	# Kolom ke-berapa gambar Leader di spritesheet kamu?
	# Misal Leader ada di urutan kedua (setelah Acrobat), isi 1.
	sprite_column = 1 # Cek gambar spritesheetmu, kolom ke berapa?
	
	ai_value = 50

func get_valid_moves(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var moves = []
	const DIRECTIONS = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	# 1. CEK KEBERADAAN VIZIER TEMAN
	var has_vizier = false
	for unit in board_state.values():
		if unit.owner_id == my_owner_id and unit.data.id == "VIZIER":
			has_vizier = true
			break
	
	# 2. HITUNG GERAKAN
	for dir in DIRECTIONS:
		var pos1 = current_pos + dir
		
		# Langkah 1 (Standar)
		if not board_state.has(pos1):
			moves.append(pos1)
			
			# Langkah 2 (Jika punya Vizier)
			if has_vizier:
				for dir2 in DIRECTIONS:
					var pos2 = pos1 + dir2
					# Tidak boleh balik ke posisi awal
					if not board_state.has(pos2) and pos2 != current_pos:
						if not moves.has(pos2):
							moves.append(pos2)
							
	return moves
