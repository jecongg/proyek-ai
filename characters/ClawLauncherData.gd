extends CharacterData
class_name ClawLauncherData

func _init():
	id = "CLAW_LAUNCHER"
	display_name = "Claw Launcher"
	description = "Menarik musuh atau bergerak ke arah mereka."
	sprite_column = 17 
	card_x = 6
	card_y = 0
	ai_value = 9
	has_active_skill = true

func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	var directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	for dir in directions:
		var check_pos = current_pos + dir
		var enemy_pos = Vector2i(999, 999)
		var found_enemy = false
		
		# Raycast: Cari musuh dulu di garis lurus
		for i in range(10):
			if board_state.has(check_pos):
				var unit = board_state[check_pos]
				if unit.owner_id != my_owner_id:
					found_enemy = true
					enemy_pos = check_pos
				break # Nabrak sesuatu (teman/musuh) berhenti
			check_pos += dir
			
		if found_enemy:
			# KITA PUNYA 2 OPSI: TARIK atau SAMPERIN
			
			# Opsi A: TARIK (Musuh ditarik ke depan muka kita)
			var pull_dest = current_pos + dir
			# Syarat: 
			# 1. Petak depan kita harus kosong
			# 2. Petak depan kita BUKAN posisi musuh itu sendiri (artinya musuh ada jarak > 1)
			if not board_state.has(pull_dest) and pull_dest != enemy_pos:
				targets.append(pull_dest)
				
			# Opsi B: SAMPERIN (Kita pindah ke depan muka musuh)
			var dash_dest = enemy_pos - dir
			# Syarat:
			# 1. Petak depan musuh harus kosong
			# 2. Petak depan musuh BUKAN posisi kita saat ini
			if not board_state.has(dash_dest) and dash_dest != current_pos:
				targets.append(dash_dest)
				
	return targets

# 2. EKSEKUSI SKILL (Berdasarkan Tile yang diklik)
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	
	# Cari arah dari Kita ke Target (atau sebaliknya)
	# Karena target_pos ada di garis lurus, kita bisa hitung arahnya
	var dir = get_direction_to_target(current_pos, target_pos)
	if dir == Vector2i.ZERO: 
		# Kasus Dash: target jauh, arahnya adalah (target - current) dinormalisasi
		dir = get_long_direction(current_pos, target_pos)
	
	if dir == Vector2i.ZERO: return false

	# ANALISA: APAKAH INI TARIK ATAU DASH?
	
	# Cek 1: Apakah target ada di SEBELAH KITA? -> Berarti TARIK
	if target_pos == (current_pos + dir):
		# Cari musuh yang ada di garis lurus sana
		var enemy_pos = find_enemy_in_direction(board_state, current_pos, dir)
		if enemy_pos != Vector2i(999, 999):
			print("CLAW: Menarik musuh dari ", enemy_pos, " ke ", target_pos)
			grid_ref.force_move_unit(enemy_pos, target_pos)
			return true
			
	# Cek 2: Apakah target JAUH? -> Berarti DASH (Samperin)
	else:
		print("CLAW: Dash menghampiri musuh di ", target_pos)
		grid_ref.force_move_unit(current_pos, target_pos)
		return true
		
	return false

# --- HELPER FUNCTIONS ---

# Cari arah tetangga (jarak 1)
func get_direction_to_target(from: Vector2i, to: Vector2i) -> Vector2i:
	var diff = to - from
	var directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	if diff in directions: return diff
	return Vector2i.ZERO

# Cari arah jarak jauh
func get_long_direction(from: Vector2i, to: Vector2i) -> Vector2i:
	var directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	for dir in directions:
		var check = from + dir
		for k in range(10):
			if check == to: return dir
			check += dir
	return Vector2i.ZERO

# Cari musuh di arah tertentu
func find_enemy_in_direction(board: Dictionary, start: Vector2i, dir: Vector2i) -> Vector2i:
	var check = start + dir
	for k in range(10):
		if board.has(check): return check # Ketemu unit pertama
		check += dir
	return Vector2i(999, 999)
