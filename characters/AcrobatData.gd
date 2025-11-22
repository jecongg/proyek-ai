# File: res://scripts/data/units/AcrobatData.gd
extends CharacterData
class_name AcrobatData

func _init():
	id = "ACROBAT"
	display_name = "The Acrobat"
	description = "Bisa melompati unit lain sejauh 2 langkah."
	sprite_frame = 0  # Frame ke-0 di spritesheet
	cost = 2

# Logic Gerak Unik Acrobat
func get_valid_moves(board_state: Dictionary, current_pos: Vector2i) -> Array:
	var moves = []
	
	# Logic: Lompat 2 langkah (Melewati 1 tile)
	var directions = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]
	
	for dir in directions:
		var target_pos = current_pos + (dir * 2)
		
		# Nanti kita tambahkan cek: Apakah target ada di dalam papan?
		# if is_valid_hex(target_pos): ...
		moves.append(target_pos)
			
	return moves
