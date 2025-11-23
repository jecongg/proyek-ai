extends Node

enum State { 
	ACTION_PHASE, 	# Pemain gerak unit / Skip
	RECRUIT_SELECT, # Pemain pilih kartu di UI
	RECRUIT_PLACE 	# Pemain taruh unit di papan
}

var current_state = State.ACTION_PHASE
var current_turn = 1
var p2_first_turn_bonus = true # Penanda bonus P2
var recruits_remaining = 0 # Berapa kartu lagi yang harus ditaruh?
var selected_card_id = ""  # Kartu apa yang sedang dipegang mouse?

@onready var grid = $"../Board"
@export var recruit_ui : Control 

func _ready():
	CardDB.initialize_deck()
	
	# Connect sinyal dari UI
	recruit_ui.card_selected.connect(_on_card_picked_from_ui)
	
	await get_tree().process_frame
	start_game()

func start_game():
	grid.spawn_unit_by_id("LEADER", grid.p1_leader_start, 1)
	grid.spawn_unit_by_id("LEADER", grid.p2_leader_start, 2)
	start_turn(1)

func start_turn(player_id):
	current_turn = player_id
	
	# --- DEBUG MODE: LANGSUNG LONCAT KE RECRUIT ---
	# Hapus baris ini nanti kalau sudah fix
	print("DEBUG: Memaksa masuk fase Recruit untuk tes UI")
	#skip_action_phase() 
	return 
	# ----------------------------------------------

	# (Kode asli di bawah ini tidak akan jalan karena return di atas)
	#current_state = State.ACTION_PHASE

# Dipanggil oleh tombol SKIP atau setelah Unit bergerak
func skip_action_phase():
	print("Action selesai/di-skip. Masuk Fase Recruit.")
	start_recruit_phase()

# --- LOGIKA RECRUITMENT ---
func start_recruit_phase():
	# 1. Cek apakah tim sudah penuh (5 orang)?
	var my_unit_count = count_units(current_turn)
	if my_unit_count >= 5:
		print("Tim Penuh (5 Unit). Skip Recruit.")
		end_turn()
		return

	# 2. Tentukan jatah rekrut
	recruits_remaining = 1
	
	# ATURAN KHUSUS: Player 2 di Turn pertamanya dapat 2 kartu
	if current_turn == 2 and p2_first_turn_bonus:
		recruits_remaining = 2
		p2_first_turn_bonus = false # Bonus hangus setelah dipakai
		print("BONUS P2: Dapat rekrut 2 kartu!")
	
	open_recruit_ui()

func open_recruit_ui():
	current_state = State.RECRUIT_SELECT
	recruit_ui.show_market()
	print("Silakan pilih kartu...")

# Sinyal dari UI
func _on_card_picked_from_ui(index):
	selected_card_id = CardDB.pick_card_from_market(index)
	current_state = State.RECRUIT_PLACE
	
	# Highlight zona spawn agar pemain tahu mau taruh di mana
	grid.highlight_spawn_zones(current_turn, true)
	print("Letakkan ", selected_card_id, " di Zona Spawn Anda.")

# Dipanggil dari GridManager saat klik Tile
func try_place_recruit(coords: Vector2i):
	if current_state != State.RECRUIT_PLACE: return
	
	# Cek 1: Apakah tile kosong?
	if grid.units_on_board.has(coords):
		print("Tile sudah terisi!")
		return
		
	# Cek 2: Apakah tile adalah Zona Spawn pemain ini?
	if not grid.is_spawn_zone(coords, current_turn):
		print("Bukan Zona Spawn Anda!")
		return
		
	# LAKUKAN SPAWN
	grid.spawn_unit_by_id(selected_card_id, coords, current_turn)
	grid.highlight_spawn_zones(current_turn, false) # Matikan highlight
	
	# Kurangi jatah
	recruits_remaining -= 1
	
	# Cek apakah harus rekrut lagi? (Kasus P2 Bonus)
	if recruits_remaining > 0:
		# Cek lagi kalau-kalau tim tiba-tiba penuh (case rare)
		if count_units(current_turn) >= 5:
			end_turn()
		else:
			print("Masih ada jatah rekrut 1 lagi!")
			open_recruit_ui() # Buka pasar lagi
	else:
		end_turn()

func end_turn():
	var next_p = 1
	if current_turn == 1: next_p = 2
	start_turn(next_p)

# Helper hitung jumlah pasukan
func count_units(player_id) -> int:
	var count = 0
	for unit in grid.units_on_board.values():
		if unit.owner_id == player_id:
			count += 1
	return count
