# ArcherData.gd
extends CharacterData
class_name ArcherData

func _init():
	id = "ARCHER"
	display_name = "Archer"
	description = "Bantu capture dari jarak 2 petak."
	sprite_column = 4
	card_x = 0
	card_y = 1
	cost = 2
	
	# Aktifkan Flag Passive
	is_archer = true
