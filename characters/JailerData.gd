extends CharacterData
class_name JailerData

func _init():
	id = "JAILER"
	display_name = "Jailer"
	description = "Musuh di sebelah tidak bisa pakai Skill."
	sprite_column = 6 
	card_x = 2
	card_y = 1
	cost = 2
	
	is_jailer = true # Flag Pasif
