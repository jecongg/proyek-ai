extends Resource
class_name CharacterData

var id : String
var display_name : String
var description : String
var cost : int

# GANTI INI: Bukan 'sprite_frame' lagi, tapi 'sprite_column'
# Ini menunjukkan urutan ke samping (Column X)
var sprite_column : int 

func get_valid_moves(board_state: Dictionary, current_pos: Vector2i) -> Array:
	return []
