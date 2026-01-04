extends CharacterData
class_name BrewmasterData

func _init():
	id = "BREWMASTER"
	display_name = "Brewmaster"
	description = "Skill: Memindahkan teman yang bersebelahan ke petak kosong di sekitarnya."
	sprite_column = 13
	card_x = 1
	card_y = 0
	ai_value = 4
	
	# PENTING: Nyalakan Active Skill
	has_active_skill = true 

const DIRECTIONS = [
	Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
	Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
]

# --- 1. TARGET SKILL (Cari petak kosong di sekitar TEMAN SEBELAH) ---
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	
	# Loop 1: Cek 6 Tetangga Brewmaster
	for dir in DIRECTIONS:
		var neighbor_pos = current_pos + dir
		
		# Apakah ada unit di sebelah?
		if board_state.has(neighbor_pos):
			var unit = board_state[neighbor_pos]
			
			# SYARAT: Harus TEMAN (Ally)
			if unit.owner_id == my_owner_id:
				
				# Loop 2: Cek sekeliling si Teman ini
				for move_dir in DIRECTIONS:
					var dest = neighbor_pos + move_dir
					
					# Syarat Destinasi:
					# 1. Harus Kosong
					# 2. Tidak boleh petak Brewmaster sendiri
					if not board_state.has(dest) and dest != current_pos:
						if not targets.has(dest):
							targets.append(dest)
							
	return targets

# --- 2. EKSEKUSI SKILL ---
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	
	# Kita tahu 'target_pos' adalah petak kosong tujuan.
	# Kita harus mencari: "Siapa teman di sebelah Brewmaster yang bisa pindah ke situ?"
	
	# Ambil ID pemilik Brewmaster untuk verifikasi teman
	var my_unit = board_state[current_pos]
	var my_owner_id = my_unit.owner_id
	
	var ally_to_move = Vector2i(999, 999)
	var found = false
	
	# Cek 6 arah dari Brewmaster
	for dir in DIRECTIONS:
		var check_pos = current_pos + dir
		
		if board_state.has(check_pos):
			var unit = board_state[check_pos]
			
			# Cek 1: Apakah ini Teman?
			if unit.owner_id == my_owner_id:
				# Cek 2: Apakah teman ini bersebelahan dengan target_pos?
				if is_neighbor(check_pos, target_pos):
					ally_to_move = check_pos
					found = true
					break
	
	if not found: return false
	
	print("BREWMASTER: Memindahkan teman dari ", ally_to_move, " ke ", target_pos)
	
	# Pindahkan Teman
	grid_ref.force_move_unit(ally_to_move, target_pos)
	
	return true

# --- HELPER: Cek Tetangga ---
func is_neighbor(a: Vector2i, b: Vector2i) -> bool:
	var diff = b - a
	return diff in DIRECTIONS
