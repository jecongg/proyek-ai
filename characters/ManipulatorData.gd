extends CharacterData
class_name ManipulatorData

func _init():
	id = "MANIPULATOR"
	display_name = "Manipulator"
	description = "Skill: Menggeser musuh (visible & non-adjacent) 1 langkah."
	sprite_column = 18 
	card_x = 7
	card_y = 0
	ai_value = 9
	
	# PENTING: Nyalakan Active Skill
	has_active_skill = true 

const DIRECTIONS = [
	Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
	Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
]

# --- 1. TARGET SKILL (Cari petak kosong di sekitar Musuh yang Valid) ---
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	
	# Langkah 1: Raycast ke 6 arah untuk cari Musuh
	for dir in DIRECTIONS:
		var check_pos = current_pos + dir
		var distance = 1
		
		# Loop Raycast (Maks 10 petak)
		for i in range(10):
			# Jika ketemu sesuatu (Unit)
			if board_state.has(check_pos):
				var unit = board_state[check_pos]
				
				# SYARAT TARGET:
				# 1. Musuh (owner beda)
				# 2. Non-Adjacent (Jarak > 1)
				if unit.owner_id != my_owner_id and distance > 1:
					
					# Musuh ini VALID untuk dimanipulasi.
					# Sekarang cari petak kosong di sekeliling musuh ini.
					var enemy_pos = check_pos
					
					for move_dir in DIRECTIONS:
						var dest = enemy_pos + move_dir
						
						# Jika petak tujuan kosong, tandai sebagai target skill
						if not board_state.has(dest):
							if not targets.has(dest):
								targets.append(dest)
				
				# Raycast berhenti jika nabrak unit (baik valid maupun tidak)
				break 
			
			# Lanjut raycast ke petak berikutnya
			check_pos += dir
			distance += 1
			
	return targets

# --- 2. EKSEKUSI SKILL ---
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	
	# 1. Cari tahu siapa musuh di sebelah 'target_pos' yang valid dilihat Manipulator
	var enemy_to_move = Vector2i(999, 999)
	var found = false
	
	for dir in DIRECTIONS:
		var potential_enemy_pos = target_pos + dir
		
		if board_state.has(potential_enemy_pos):
			# Validasi ulang visibilitas
			if is_visible_and_non_adjacent(board_state, current_pos, potential_enemy_pos):
				enemy_to_move = potential_enemy_pos
				found = true
				break
	
	if not found: return false
	
	# --- PERUBAHAN DI SINI ---
	# 2. Eksekusi perpindahan dan cek apakah berhasil (tidak diblokir Protector)
	var success = grid_ref.force_move_unit(enemy_to_move, target_pos)

	if not success:
		# Jika force_move_unit mengembalikan 'false', berarti target dilindungi
		print("MANIPULATOR: Gagal menggeser musuh karena dilindungi Protector!")
		return false # Skill dianggap gagal/tidak terpakai
	else:
		# Jika 'true', berarti musuh berhasil digeser
		print("MANIPULATOR: Berhasil menggerakkan musuh dari ", enemy_to_move, " ke ", target_pos)
		return true # Skill sukses

# --- HELPER: Cek Visibility & Jarak ---
func is_visible_and_non_adjacent(board_state: Dictionary, my_pos: Vector2i, target_pos: Vector2i) -> bool:
	# 1. Cek Non-Adjacent (Tidak boleh tetangga)
	var diff = target_pos - my_pos
	if diff in DIRECTIONS: return false # Terlalu dekat
	
	# 2. Cek Segaris & Visible (Raycast manual)
	# Kita cari arah vektornya
	var dir = Vector2i.ZERO
	
	for d in DIRECTIONS:
		var check = my_pos + d
		# Cek apakah target ada di garis lurus arah d
		for k in range(10):
			if check == target_pos:
				dir = d
				break
			check += d
		if dir != Vector2i.ZERO: break
	
	if dir == Vector2i.ZERO: return false # Tidak segaris
	
	# 3. Cek apakah ada halangan di tengah?
	var scanner = my_pos + dir
	while scanner != target_pos:
		if board_state.has(scanner):
			return false # Terhalang unit lain
		scanner += dir
		
	return true
