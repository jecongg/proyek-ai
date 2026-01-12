extends CharacterData
class_name RoyalGuardData

const DIRECTIONS = [
	Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
	Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
]

func _init():
	id = "ROYAL_GUARD"
	display_name = "Royal Guard"
	description = "Skill: Teleport ke sebelah Leader, lalu boleh gerak 1 langkah lagi."
	sprite_column = 15
	card_x = 4
	card_y = 0
	ai_value = 7
	has_active_skill = true

# --- GERAKAN STANDAR ---
func get_valid_moves(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var moves = []
	for dir in DIRECTIONS:
		var target = current_pos + dir
		if not board_state.has(target): 
			moves.append(target)
	return moves

# --- TARGET SKILL ---
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	var leader_pos = Vector2i(999, 999)
	var found = false
	
	for coord in board_state:
		var unit = board_state[coord]
		if unit.data.id == "LEADER" and unit.owner_id == my_owner_id:
			leader_pos = coord
			found = true
			break
	
	if not found: return [] 
	
	var zone_1_tiles = []
	for dir in DIRECTIONS:
		var pos = leader_pos + dir
		if not board_state.has(pos):
			zone_1_tiles.append(pos)
			if not targets.has(pos):
				targets.append(pos)
	
	for start_node in zone_1_tiles:
		for dir in DIRECTIONS:
			var pos_2 = start_node + dir
			if not board_state.has(pos_2) and pos_2 != current_pos:
				if not targets.has(pos_2):
					targets.append(pos_2)
					
	return targets

# --- EKSEKUSI SKILL ---
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	if board_state.has(target_pos): return false
	
	var my_owner_id = board_state[current_pos].owner_id
	var leader_pos = Vector2i(999,999)
	for coord in board_state:
		if board_state[coord].data.id == "LEADER" and board_state[coord].owner_id == my_owner_id:
			leader_pos = coord
			break
	
	var is_adj_to_leader = is_neighbor(target_pos, leader_pos)
	
	if is_adj_to_leader:
		grid_ref.force_move_unit(current_pos, target_pos)
	else:
		var stepping_stone = Vector2i(999,999)
		for dir in DIRECTIONS:
			var potential = leader_pos + dir
			if is_neighbor(potential, target_pos) and not board_state.has(potential):
				stepping_stone = potential
				break
		
		if stepping_stone != Vector2i(999,999):
			grid_ref.force_move_unit(current_pos, stepping_stone)
			await grid_ref.get_tree().create_timer(0.3).timeout
			grid_ref.force_move_unit(stepping_stone, target_pos)
		else:
			grid_ref.force_move_unit(current_pos, target_pos)
			
	return true

func is_neighbor(a: Vector2i, b: Vector2i) -> bool:
	var diff = b - a
	return diff in DIRECTIONS
