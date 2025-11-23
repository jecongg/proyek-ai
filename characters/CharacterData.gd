extends Resource
class_name CharacterData

# --- STATS ---
var id : String
var display_name : String
var description : String
var sprite_column : int   # Untuk Unit di Papan
var card_x : int = 0  # Posisi Kolom (Kiri-Kanan)
var card_y : int = 0  # Posisi Baris (Atas-Bawah)
var cost : int = 0

# --- PASSIVE FLAGS (Sesuai Rulebook Hal 7) ---
var is_assassin : bool = false # Bisa capture sendirian
var is_archer : bool = false   # Bisa bantu capture dari jarak 2
var is_jailer : bool = false   # Memblokir skill musuh sebelah
var is_protector : bool = false # Tidak bisa didorong/ditarik
var grants_extra_move_to_leader : bool = false # Efek Vizier

# --- FUNGSI VIRTUAL ---
func get_valid_moves(board_state: Dictionary, current_pos: Vector2i) -> Array:
	# Default Gerakan: 1 Langkah ke tetangga (Move to adjacent empty space)
	# Sesuai Rulebook Hal 4: "Action Phase: Move to adjacent OR Use Ability"
	
	var moves = []
	var directions = [
		Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
	]
	
	for dir in directions:
		var target = current_pos + dir
		# Validasi dasar: Hanya bisa gerak ke tile kosong
		# (Nanti divalidasi lagi di GridManager apakah tile itu valid/ada di map)
		if not board_state.has(target): 
			moves.append(target)
			
	return moves

# Fungsi untuk Active Ability (Skill Tombol Petir Merah)
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i) -> Array:
	return [] # Default unit biasa tidak punya skill aktif
