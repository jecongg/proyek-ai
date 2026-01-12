# AssassinData.gd
extends CharacterData
class_name AssassinData

func _init():
	id = "ASSASSIN"
	display_name = "Assassin"
	description = "Bisa membunuh Leader sendirian."
	sprite_column = 9
	card_x = 1
	card_y = 1
	ai_value = 10
	
	is_assassin = true 
