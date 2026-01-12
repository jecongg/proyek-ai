extends Resource
class_name CharacterData

var id : String
var display_name : String
var description : String
var sprite_column : int  
var card_x : int = 0 
var card_y : int = 0 
var ai_value : int = 5

var is_assassin : bool = false 
var is_archer : bool = false  
var is_jailer : bool = false  
var is_protector : bool = false 
var grants_extra_move_to_leader : bool = false
var can_capture_leader : bool = true 
var has_active_skill : bool = false

# --- FUNGSI VIRTUAL ---
func get_valid_moves(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var moves = []
	var directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	for dir in directions:
		var target = current_pos + dir
		if not board_state.has(target): 
			moves.append(target)
			
	return moves

func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	return []
	
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_manager_ref) -> bool:
	return false
	
