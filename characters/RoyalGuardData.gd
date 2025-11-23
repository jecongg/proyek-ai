# RoyalGuardData.gd
extends CharacterData
class_name RoyalGuardData

func _init():
	id = "ROYAL_GUARD"
	display_name = "Royal Guard"
	description = "Gerak ke sebelah Leader kita."
	sprite_column = 15
	card_x = 4
	card_y = 0
	cost = 1

func get_valid_moves(board_state: Dictionary, current_pos: Vector2i) -> Array:
	var moves = []
	var directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	# 1. Cari Posisi Leader Teman
	var my_leader_pos = Vector2i.ZERO
	var found = false
	
	# board_state isinya: { koordinat : UnitNode }
	for coord in board_state:
		var unit = board_state[coord]
		# Kita butuh check owner_id di sini, tapi Resource gak tau owner_id unit ini siapa
		# Nanti kita harus passing owner_id ke fungsi ini
		if unit.data.id == "LEADER": 
			# if unit.owner_id == my_owner_id: (Logic ini harus ditambah di GridManager)
			my_leader_pos = coord
			found = true
			break
	
	if not found: return []
	
	# 2. Cari area kosong di sekitar Leader
	for dir in directions:
		var target = my_leader_pos + dir
		if not board_state.has(target):
			moves.append(target)
			
			# Royal Guard boleh gerak 1 langkah lagi dari situ
			for dir2 in directions:
				var extra_step = target + dir2
				if not board_state.has(extra_step):
					moves.append(extra_step)
					
	return moves
