# File: res://scripts/data/CharacterData.gd
extends Resource
class_name CharacterData

# Stats Dasar
var id : String
var display_name : String
var description : String
var sprite_frame : int
var cost : int

# Fungsi Virtual (Wajib di-override oleh anak-anaknya)
func get_valid_moves(board_state: Dictionary, current_pos: Vector2i) -> Array:
	return []
