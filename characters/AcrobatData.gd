extends CharacterData
class_name AcrobatData

func _init():
	id = "ACROBAT"
	display_name = "The Acrobat"
	description = "Melompati unit lain sejauh 2 langkah."
	sprite_column = 8
	card_x = 0
	card_y = 0
	ai_value = 4
	has_active_skill = true 

func get_valid_moves(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var moves = []
	const directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	for dir in directions:
		var target = current_pos + dir
		if not board_state.has(target): 
			moves.append(target)
			
	return moves

# --- 2. TARGET SKILL (Lompatan) ---
# Mencari titik pendaratan lompatan (1x atau 2x)
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	const directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	# --- LOMPATAN PERTAMA ---
	for dir in directions:
		var mid_pos = current_pos + dir          # Batu loncatan (harus ada orang)
		var land_pos_1 = current_pos + (dir * 2) # Pendaratan 1 (harus kosong)
		
		# Syarat: Ada orang di tengah & Tujuan kosong
		if board_state.has(mid_pos) and not board_state.has(land_pos_1):
			
			# Tambahkan Pendaratan 1 sebagai opsi
			if not targets.has(land_pos_1):
				targets.append(land_pos_1)
			
			# --- LOMPATAN KEDUA (Combo) ---
			# Cek lagi dari posisi pendaratan 1
			for dir2 in directions:
				var mid_pos_2 = land_pos_1 + dir2
				var land_pos_2 = land_pos_1 + (dir2 * 2)
				
				# Tidak boleh balik ke posisi awal (aturan umum)
				if land_pos_2 != current_pos:
					if board_state.has(mid_pos_2) and not board_state.has(land_pos_2):
						
						# Tambahkan Pendaratan 2 sebagai opsi
						if not targets.has(land_pos_2):
							targets.append(land_pos_2)
							
	return targets

# --- 3. EKSEKUSI SKILL ---
# Pindahkan unit ke titik pendaratan yang dipilih
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	if board_state.has(target_pos): return false
	
	const directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	# 1. Cek apakah ini Lompatan 1 (Jarak 2 petak lurus)
	var diff = target_pos - current_pos
	var is_single_jump = false
	for dir in directions:
		if diff == dir * 2:
			is_single_jump = true
			break
			
	if is_single_jump:
		print("ACROBAT: Lompat 1x")
		grid_ref.force_move_unit(current_pos, target_pos)
	else:
		# 2. Ini adalah Lompatan 2 (Combo)
		# Cari titik pendaratan pertama (land_pos_1) yang menghubungkan start ke target
		var first_landing = Vector2i(999,999)
		
		for dir1 in directions:
			var p1 = current_pos + (dir1 * 2)
			var mid1 = current_pos + dir1
			
			# Syarat pendaratan pertama: Ada orang di tengah & Petaknya kosong
			if board_state.has(mid1) and not board_state.has(p1):
				# Cek apakah dari pendaratan pertama bisa sampai ke target_pos
				for dir2 in directions:
					var p2 = p1 + (dir2 * 2)
					if p2 == target_pos:
						first_landing = p1
						break
			if first_landing != Vector2i(999,999): break
			
		if first_landing != Vector2i(999,999):
			print("ACROBAT: Melakukan Double Jump!")
			# Lompatan Pertama
			grid_ref.force_move_unit(current_pos, first_landing)
			# Jeda sebentar agar terlihat "berturut-turut" sesuai rulebook
			await grid_ref.get_tree().create_timer(0.3).timeout
			# Lompatan Kedua
			grid_ref.force_move_unit(first_landing, target_pos)
		else:
			# Safety fall: Jika tidak terdeteksi combo, langsung pindah
			grid_ref.force_move_unit(current_pos, target_pos)
			
	return true
