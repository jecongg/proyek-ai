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
	
	has_active_skill = true 

const DIRECTIONS = [
	Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
	Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
]

# --- TARGET SKILL (Cari petak kosong di sekitar Musuh yang Valid) ---
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	
	for dir in DIRECTIONS:
		var check_pos = current_pos + dir
		var distance = 1
		
		for i in range(10):
			if board_state.has(check_pos):
				var unit = board_state[check_pos]

				if unit.owner_id != my_owner_id and distance > 1:
					var enemy_pos = check_pos
					
					for move_dir in DIRECTIONS:
						var dest = enemy_pos + move_dir
						
						if not board_state.has(dest):
							if not targets.has(dest):
								targets.append(dest)
				
				break 
			
			check_pos += dir
			distance += 1
			
	return targets

# --- EKSEKUSI SKILL ---
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:

	var enemy_to_move = Vector2i(999, 999)
	var found = false
	
	for dir in DIRECTIONS:
		var potential_enemy_pos = target_pos + dir
		
		if board_state.has(potential_enemy_pos):
			if is_visible_and_non_adjacent(board_state, current_pos, potential_enemy_pos):
				enemy_to_move = potential_enemy_pos
				found = true
				break
	
	if not found: return false
	
	var success = grid_ref.force_move_unit(enemy_to_move, target_pos)

	if not success:
		print("MANIPULATOR: Gagal menggeser musuh karena dilindungi Protector!")
		return false 
	else:
		print("MANIPULATOR: Berhasil menggerakkan musuh dari ", enemy_to_move, " ke ", target_pos)
		return true

# --- Cek Visibility & Jarak ---
func is_visible_and_non_adjacent(board_state: Dictionary, my_pos: Vector2i, target_pos: Vector2i) -> bool:
	var diff = target_pos - my_pos
	if diff in DIRECTIONS: return false 

	var dir = Vector2i.ZERO
	
	for d in DIRECTIONS:
		var check = my_pos + d
		for k in range(10):
			if check == target_pos:
				dir = d
				break
			check += d
		if dir != Vector2i.ZERO: break
	
	if dir == Vector2i.ZERO: return false
	
	var scanner = my_pos + dir
	while scanner != target_pos:
		if board_state.has(scanner):
			return false 
		scanner += dir
		
	return true
