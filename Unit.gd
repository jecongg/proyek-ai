extends Node2D

@onready var sprite = $Sprite2D

# PENTING: Ini adalah "Jiwa" unit ini
var data : CharacterData 
var grid_pos : Vector2i
var owner_id : int

func setup(new_data: CharacterData, start_pos: Vector2i, new_owner: int):
	data = new_data # Simpan resource-nya
	grid_pos = start_pos
	owner_id = new_owner
	
	# Update Visual otomatis dari Data
	sprite.frame = data.sprite_frame
	
	# Kalau musuh, ubah warna dikit
	if owner_id == 2:
		modulate = Color(1, 0.5, 0.5)

# Saat mau gerak, Unit tanya ke "Jiwa"-nya
func get_moves(board_state):
	return data.get_valid_moves(board_state, grid_pos)
