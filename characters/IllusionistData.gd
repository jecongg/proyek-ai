extends CharacterData
class_name IllusionistData

func _init():
	id = "ILLUSIONIST"
	display_name = "Illusionist"
	description = "Skill: Bertukar tempat dengan unit lain (Teman/Musuh) yang terlihat & tidak bersebelahan."
	sprite_column = 19
	card_x = 5
	card_y = 0
	ai_value = 7
	
	# PENTING: Nyalakan Active Skill
	has_active_skill = true 

const DIRECTIONS = [
	Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
	Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
]

# --- 1. TARGET SKILL (Cari Unit di Garis Lurus) ---
func get_skill_targets(board_state: Dictionary, current_pos: Vector2i, my_owner_id: int) -> Array:
	var targets = []
	
	for dir in DIRECTIONS:
		var check_pos = current_pos + dir
		var distance = 1
		
		# Raycast: Cek lurus sampai ketemu unit atau ujung
		for i in range(10):
			# Cek apakah ada unit di petak ini?
			if board_state.has(check_pos):
				# ADA UNIT!
				
				# Syarat 1: Non-Adjacent (Jarak > 1)
				if distance > 1:
					# Syarat 2: Visible (Sudah pasti visible karena ini unit pertama yang kita tabrak raycast)
					targets.append(check_pos)
				
				# Raycast BERHENTI di sini.
				# Kita tidak bisa melihat unit di belakang unit ini (terhalang).
				# Jika distance == 1 (tetangga), kita berhenti tanpa menambahkan target.
				break 
			
			# Jika tile kosong, lanjut cek petak berikutnya
			check_pos += dir
			distance += 1
			
	return targets

# --- 2. EKSEKUSI SKILL (Swap) ---
func resolve_skill(board_state: Dictionary, current_pos: Vector2i, target_pos: Vector2i, grid_ref) -> bool:
	# Cek apakah target valid (harus ada unitnya)
	if not board_state.has(target_pos): return false
	
	print("ILLUSIONIST: Bertukar tempat dengan unit di ", target_pos)
	
	# Panggil fungsi khusus SWAP di GridManager
	grid_ref.swap_units(current_pos, target_pos)
	
	return true
