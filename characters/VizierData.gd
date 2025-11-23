# VizierData.gd
extends CharacterData
class_name VizierData

func _init():
	id = "VIZIER"
	display_name = "Vizier"
	description = "Leader kamu bisa gerak lebih jauh."
	sprite_column = 16
	card_x = 4
	card_y = 1
	cost = 2
	
	grants_extra_move_to_leader = true
