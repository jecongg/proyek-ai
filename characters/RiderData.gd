# RiderData.gd
extends CharacterData
class_name RiderData

func _init():
	id = "RIDER"
	display_name = "Rider"
	description = "Bergerak 2 langkah lurus."
	sprite_column = 10
	card_x = 2
	card_y = 0
	cost = 1

func get_valid_moves(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var moves = []
	var directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	for dir in directions:
		# Langkah 1
		var pos1 = current_pos + dir
		if not board_state.has(pos1): # Jika kosong
			moves.append(pos1)
			
			# Langkah 2 (Lurus)
			var pos2 = pos1 + dir
			if not board_state.has(pos2): # Jika kosong juga
				moves.append(pos2)
				
	return moves
