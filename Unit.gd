extends Node2D

@onready var sprite = $Sprite2D

var data : CharacterData 
var grid_pos : Vector2i
var owner_id : int

# VARIABLE BARU
var has_moved : bool = false 

func setup(new_data: CharacterData, start_pos: Vector2i, new_owner: int):
	data = new_data
	grid_pos = start_pos
	owner_id = new_owner
	
	# Reset status
	has_moved = false
	modulate = Color.WHITE
	
	# Logika Visual Frame (Tetap sama)
	var row_index = 0
	if owner_id == 2:
		row_index = 1 
	sprite.frame_coords = Vector2i(data.sprite_column, row_index)

# Fungsi Baru: Reset saat ganti giliran
func reset_turn_state():
	has_moved = false
	modulate = Color.WHITE # Kembali cerah

# Fungsi Baru: Tandai sudah gerak
func mark_as_moved():
	has_moved = true
	modulate = Color(0.6, 0.6, 0.6) # Jadi agak gelap (Exhausted)
