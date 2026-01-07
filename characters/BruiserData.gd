extends CharacterData
class_name BruiserData

func _init():
	id = "BRUISER"
	display_name = "Bruiser"
	description = "Skill: Mendorong musuh dan menempati posisinya."
	sprite_column = 5 
	card_x = 3
	card_y = 0
	ai_value = 6
	has_active_skill = true 

# --- 1. GERAKAN STANDAR (Tanpa Skill) ---
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

# --- 2. TARGET SKILL (Cari Petak Kosong di Belakang Musuh) ---
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	const directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	# Loop 1: Cari Musuh di Sebelah
	for dir in directions:
		var enemy_pos = current_pos + dir
		
		# Cek apakah ada unit & itu musuh
		if board_state.has(enemy_pos):
			var unit = board_state[enemy_pos]
			if unit.owner_id != my_owner_id:
				
				# Loop 2: Cari 3 Titik di "Belakang" Musuh
				# Definisi "Belakang" = Tetangga Musuh yang BUKAN tetangga Bruiser
				for dir2 in directions:
					var push_dest = enemy_pos + dir2
					
					# Syarat Valid Push:
					# 1. Tile tujuan harus kosong
					# 2. Tile tujuan TIDAK BOLEH posisi Bruiser saat ini (jelas)
					# 3. Tile tujuan TIDAK BOLEH bersebelahan dengan Bruiser (karena itu namanya geser samping, bukan dorong)
					if not board_state.has(push_dest):
						if push_dest != current_pos and not is_neighbor(current_pos, push_dest):
							if not targets.has(push_dest):
								targets.append(push_dest)
								
	return targets

# --- 3. EKSEKUSI SKILL ---
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	const directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	var enemy_pos = Vector2i(999, 999)
	var found = false
	
	for dir in directions:
		var check = current_pos + dir
		if board_state.has(check):
			if is_neighbor(check, target_pos):
				enemy_pos = check
				found = true
				break
	
	if not found: return false
	
	# --- PERUBAHAN DI SINI ---
	# Coba dorong musuh dulu
	var push_success = grid_ref.force_move_unit(enemy_pos, target_pos)
	
	if push_success:
		# Hanya jika musuh pindah, Bruiser maju mengisi tempatnya
		print("BRUISER: Berhasil mendorong musuh, sekarang maju.")
		grid_ref.force_move_unit(current_pos, enemy_pos)
		return true
	else:
		# Jika gagal (kena Protector), Bruiser tetap diam di tempat
		print("BRUISER: Gagal mendorong karena target dilindungi!")
		return false

# --- HELPER: Cek apakah A dan B tetanggaan ---
func is_neighbor(a: Vector2i, b: Vector2i) -> bool:
	var diff = b - a
	const directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	return diff in directions
