extends CharacterData
class_name WandererData

func _init():
	id = "WANDERER"
	display_name = "Wanderer"
	description = "Skill: Teleport ke petak manapun yang tidak bersebelahan dengan musuh."
	sprite_column = 7 
	card_x = 8
	card_y = 0
	ai_value = 6
	
	has_active_skill = true 

# --- GERAKAN STANDAR (Tanpa Skill) ---
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

# --- TARGET SKILL (Cari Semua Petak Aman) ---
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	var scan_range_q = range(-4, 5) 
	var scan_range_r = range(-7, 8) 
	
	for q in scan_range_q:
		for r in scan_range_r:
			var check_pos = Vector2i(q, r)

			if not board_state.has(check_pos):
			
				if is_safe_from_enemies(check_pos, board_state, my_owner_id):
					targets.append(check_pos)
					
	return targets

# --- EKSEKUSI SKILL ---
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	if board_state.has(target_pos): return false
	
	print("WANDERER: Terbang ke ", target_pos)
	
	grid_ref.force_move_unit(current_pos, target_pos)
	
	return true

# --- Cek Tetangga ---
func is_safe_from_enemies(pos: Vector2i, board_state: Dictionary, my_id: int) -> bool:
	const directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	for dir in directions:
		var neighbor = pos + dir
		if board_state.has(neighbor):
			var unit = board_state[neighbor]
			if unit.owner_id != my_id:
				return false
				
	return true
