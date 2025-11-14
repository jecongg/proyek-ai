extends Node2D

# Variabel untuk menyimpan state permainan
var board_state = [[null, null, null], [null, null, null], [null, null, null]]
var current_turn = "X"
var game_over = false

# Tekstur untuk X dan O yang akan kita muat dari file aset
var texture_x = preload("res://assets/x.png")
var texture_o = preload("res://assets/o.png")

#func _ready():
	#start_new_game()
