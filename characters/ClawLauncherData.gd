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
		var target_unit_pos = Vector2i(999, 999)
		var found_character = false
		
		for i in range(10):
			if board_state.has(check_pos):
				found_character = true
				target_unit_pos = check_pos
				break 
			check_pos += dir
			
		if found_character:
			var pull_dest = current_pos + dir
			if not board_state.has(pull_dest) and pull_dest != target_unit_pos:
				targets.append(pull_dest)
				
			var dash_dest = target_unit_pos - dir
			if not board_state.has(dash_dest) and dash_dest != current_pos:
				targets.append(dash_dest)
				
	return targets

func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	var dir = get_long_direction(current_pos, target_pos)
	if dir == Vector2i.ZERO: return false

	# ANALISA: TARIK atau DASH?
	if target_pos == (current_pos + dir):
		var char_pos = find_character_in_direction(board_state, current_pos, dir)
		if char_pos != Vector2i(999, 999):
			var success = grid_ref.force_move_unit(char_pos, target_pos)
			if not success:
				print("CLAW: Gagal menarik! Target dilindungi Protector.")
			return success
	else:
		print("CLAW: Dash menghampiri karakter.")
		grid_ref.force_move_unit(current_pos, target_pos)
		return true
		
	return false

# Helper untuk cari karakter (siapa saja) di arah tertentu
func find_character_in_direction(board: Dictionary, start: Vector2i, dir: Vector2i) -> Vector2i:
	var check = start + dir
	for k in range(10):
		if board.has(check): return check 
		check += dir
	return Vector2i(999, 999)

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
		if board.has(check): return check
		check += dir
	return Vector2i(999, 999)
