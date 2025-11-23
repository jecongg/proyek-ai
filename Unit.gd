extends Node2D

@onready var sprite = $Sprite2D

# PENTING: Ini adalah "Jiwa" unit ini
var data : CharacterData 
var grid_pos : Vector2i
var owner_id : int

func setup(new_data: CharacterData, start_pos: Vector2i, new_owner: int):
	data = new_data
	grid_pos = start_pos
	owner_id = new_owner
	
	# --- LOGIKA VISUAL BARU (FRAME COORDS) ---
	# Asumsi: 
	# Row 0 (Atas) = Player 1
	# Row 1 (Bawah) = Player 2
	
	var row_index = 0
	if owner_id == 2:
		row_index = 1 # Gunakan baris kedua spritesheet
	
	# Set koordinat frame: (Kolom X, Baris Y)
	sprite.frame_coords = Vector2i(data.sprite_column, row_index)
	
	# (Opsional) Matikan modulate warna jika spritesheet-nya sudah beda warna
	# modulate = Color.WHITE

# Saat mau gerak, Unit tanya ke "Jiwa"-nya
func get_moves(board_state):
	return data.get_valid_moves(board_state, grid_pos)
