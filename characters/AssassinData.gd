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
	
	# Aktifkan Flag Passive
	is_assassin = true 
	# (Nanti di GridManager.check_win_condition kita cek flag ini)
