extends CharacterData
class_name CubData

func _init():
	id = "CUB"
	display_name = "The Cub"
	description = "Hewan peliharaan Hermit. Tidak bisa capture Leader."
	sprite_column = 12
	card_x = 0
	card_y = 0
	ai_value = 1
	
	can_capture_leader = false # Flag Khusus
