extends CharacterData
class_name RoyalGuardData

func _init():
	id = "ROYAL_GUARD"
	display_name = "Royal Guard"
	description = "Skill: Teleport ke sebelah Leader, lalu boleh gerak 1 langkah lagi."
	sprite_column = 15
	card_x = 4
	card_y = 0
	ai_value = 7
	
	# PENTING: Nyalakan Skill Aktif
	has_active_skill = true

# --- 1. GERAKAN STANDAR (Tanpa Skill) ---
# Hanya bisa jalan kaki 1 langkah
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

# --- 2. TARGET SKILL (Teleport ke Leader + 1 Langkah) ---
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	const directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	# A. Cari Leader Kita
	var leader_pos = Vector2i(999, 999)
	var found = false
	
	for coord in board_state:
		var unit = board_state[coord]
		if unit.data.id == "LEADER" and unit.owner_id == my_owner_id:
			leader_pos = coord
			found = true
			break
	
	if not found: return [] # Gak ada leader, gak bisa skill
	
	# B. Hitung Area Valid (Zone 1 & Zone 2)
	
	# ZONE 1: Petak persis di sebelah Leader
	var zone_1_tiles = []
	
	for dir in directions:
		var pos = leader_pos + dir
		# Syarat: Harus kosong
		if not board_state.has(pos):
			zone_1_tiles.append(pos)
			
			# Masukkan ke targets (Opsi jika player cuma mau gerak sampai sini)
			if not targets.has(pos):
				targets.append(pos)
	
	# ZONE 2: Petak di sebelah Zone 1 (Langkah Tambahan)
	for start_node in zone_1_tiles:
		for dir in directions:
			var pos_2 = start_node + dir
			
			# Syarat:
			# 1. Harus kosong
			# 2. Tidak boleh balik ke posisi Leader (jelas, karena ada isinya)
			# 3. Tidak boleh posisi Royal Guard saat ini (diam di tempat)
			if not board_state.has(pos_2) and pos_2 != current_pos:
				if not targets.has(pos_2):
					targets.append(pos_2)
					
	return targets

# --- 3. EKSEKUSI SKILL ---
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	# Cek sederhana apakah target kosong
	if board_state.has(target_pos): return false
	
	print("ROYAL GUARD: Melindungi Leader di ", target_pos)
	
	# Pindahkan unit (Teleport)
	grid_ref.force_move_unit(current_pos, target_pos)
	
	return true
