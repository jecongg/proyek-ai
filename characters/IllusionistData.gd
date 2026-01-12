extends CharacterData
class_name IllusionistData

func _init():
	id = "ILLUSIONIST"
	display_name = "Illusionist"
	description = "Skill: Bertukar tempat dengan unit lain (Teman/Musuh) yang terlihat & tidak bersebelahan."
	sprite_column = 19
	card_x = 5
	card_y = 0
	ai_value = 7
	
	has_active_skill = true 

const DIRECTIONS = [
	Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
	Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
]

# --- TARGET SKILL (Cari Unit di Garis Lurus) ---
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	
	for dir in DIRECTIONS:
		var check_pos = current_pos + dir
		var distance = 1
		
		for i in range(10):
			if board_state.has(check_pos):
				if distance > 1:
					targets.append(check_pos)
				break 
			
			check_pos += dir
			distance += 1
			
	return targets

# --- EKSEKUSI SKILL (Swap) ---
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	if not board_state.has(target_pos): return false
	
	print("ILLUSIONIST: Bertukar tempat dengan unit di ", target_pos)
	
	grid_ref.swap_units(current_pos, target_pos)
	
	return true
