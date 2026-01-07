# RiderData.gd
extends CharacterData
class_name RiderData

func _init():
	id = "RIDER"
	display_name = "Rider"
	description = "Skill: Bergerak 2 langkah lurus melewati petak kosong."
	sprite_column = 10
	card_x = 2
	card_y = 0
	ai_value = 8
	
	# PENTING: Aktifkan flag Skill Aktif sesuai Rulebook Hal 6
	has_active_skill = true

# --- 1. GERAKAN STANDAR (1 Langkah) ---
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

# --- 2. TARGET SKILL (2 Langkah Lurus) ---
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	const directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	for dir in directions:
		var pos1 = current_pos + dir
		var pos2 = pos1 + dir
		
		# Syarat Rulebook: Harus melewati petak kosong (Lurus)
		# Berbeda dengan Acrobat yang melompati orang, Rider butuh jalan yang bersih
		if not board_state.has(pos1): 
			if not board_state.has(pos2):
				targets.append(pos2)
				
	return targets

# --- 3. EKSEKUSI SKILL ---
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	if board_state.has(target_pos): return false
	
	print("RIDER: Melakukan dash 2 langkah ke ", target_pos)
	grid_ref.force_move_unit(current_pos, target_pos)
	return true
