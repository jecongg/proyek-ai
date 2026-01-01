extends CharacterData
class_name NemesisData

func _init():
	id = "NEMESIS"
	display_name = "Nemesis"
	description = "Mengejar Leader musuh secara otomatis (Pasif)."
	sprite_column = 3 
	card_x = 5
	card_y = 1
	ai_value = 3

# Override supaya TIDAK BISA GERAK MANUAL
func get_valid_moves(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	return []
