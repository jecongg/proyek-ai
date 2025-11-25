extends Node

enum State { ACTION_PHASE, RECRUIT_SELECT, RECRUIT_PLACE }

var current_state = State.ACTION_PHASE
var current_turn = 1
var p2_first_turn_bonus = true 
var recruits_remaining = 0 
var selected_card_id = ""  

@onready var grid = $"../Board"
@export var recruit_ui : Control 
@onready var info_label = $"../UILayer/InfoLabel" # Referensi ke Label Baru
var ai_brain : AIBrain

func _ready():
	ai_brain = AIBrain.new(grid)
	add_child(ai_brain)
	CardDB.initialize_deck()
	recruit_ui.card_selected.connect(_on_card_picked_from_ui)
	await get_tree().process_frame
	start_game()

func start_game():
	grid.spawn_unit_by_id("LEADER", grid.p1_leader_start, 1)
	grid.spawn_unit_by_id("LEADER", grid.p2_leader_start, 2)
	start_turn(1)

#func start_turn(player_id):
	#current_turn = player_id
	#current_state = State.ACTION_PHASE
	#
	## --- UPDATE UI TEKS ---
	#info_label.text = "GILIRAN PLAYER " + str(current_turn) + "\n(Pilih Unit untuk Gerak atau SKIP)"
	#if current_turn == 1:
		#info_label.modulate = Color.WHITE
	#else:
		#info_label.modulate = Color(1, 0.5, 0.5) # Merah muda buat P2
	#
	## --- RESET SEMUA UNIT DI PAPAN ---
	## Supaya unit player ini bisa gerak lagi
	#for unit in grid.units_on_board.values():
		#if unit.owner_id == current_turn:
			#unit.reset_turn_state() # Balikin warna jadi cerah
	#
	#print("Giliran Player ", current_turn, " Dimulai.")

func start_turn(player_id):
	current_turn = player_id
	current_state = State.ACTION_PHASE
	
	# ... Kode UI Label ...
	info_label.text = "GILIRAN PLAYER " + str(current_turn)
	
	# Reset unit
	for unit in grid.units_on_board.values():
		if unit.owner_id == current_turn:
			unit.reset_turn_state()
			
	print("Giliran Player ", current_turn, " Dimulai.")
	
	# --- INTEGRASI AI ---
	if current_turn == 2: # Jika giliran AI (Player 2)
		info_label.text += " (AI SEDANG BERPIKIR...)"
		
		# Beri jeda sedikit biar tidak kaget
		await get_tree().create_timer(1.0).timeout
		perform_ai_action_phase()

func perform_ai_action_phase():
	# Minta otak AI mencari langkah terbaik
	var best_move = ai_brain.get_best_move(grid.units_on_board, current_turn)
	
	if best_move != null:
		print("AI Memilih Gerak: ", best_move["from"], " -> ", best_move["to"])
		grid.execute_move(best_move["from"], best_move["to"])
		# on_action_performed akan dipanggil oleh GridManager setelah gerak
	else:
		print("AI tidak menemukan langkah bagus. Skip.")
		skip_action_phase()

# Callback baru dari GridManager setelah unit bergerak
func on_action_performed():
	# Setelah gerak, AI biasanya langsung selesai Action Phase (karena 1 turn 1 move di rule dasar?)
	# Atau jika unit masih bisa gerak (rule khusus), bisa logic lain.
	# Untuk sekarang, kita anggap setelah gerak langsung ke Recruit.
	
	# Tunggu animasi selesai
	await get_tree().create_timer(0.6).timeout
	
	if current_turn == 2:
		skip_action_phase() # AI lanjut ke Recruit Phase

# --- RECRUITMENT AI (Simple Greedy) ---
# AI Recruit Phase Logic
func start_recruit_phase():
	# ... (Kode cek unit penuh sama seperti player) ...
	if count_units(current_turn) >= 5:
		end_turn()
		return

	recruits_remaining = 1
	if current_turn == 2 and p2_first_turn_bonus:
		recruits_remaining = 2
		p2_first_turn_bonus = false
	
	if current_turn == 1:
		open_recruit_ui()
	else:
		# AI Logic untuk Recruit
		do_ai_recruit()

func do_ai_recruit():
	await get_tree().create_timer(0.5).timeout
	
	# AI Loop Recruit
	while recruits_remaining > 0:
		# 1. Pilih Kartu Terbaik (Greedy: Ambil yang cost-nya paling mahal/kuat)
		var best_idx = -1
		var best_cost = -1
		
		for i in range(CardDB.market_cards.size()):
			var card_id = CardDB.market_cards[i]
			if card_id == "": continue
			# Kita butuh data dummy untuk cek cost
			if CardDB.library.has(card_id):
				var d = CardDB.library[card_id].new()
				if d.cost > best_cost:
					best_cost = d.cost
					best_idx = i
		
		if best_idx != -1:
			var card_id = CardDB.pick_card_from_market(best_idx)
			print("AI Membeli Unit: ", card_id)
			
			# 2. Pilih Posisi Spawn Terbaik
			# (Greedy: Pilih spawn zone yang paling dekat ke musuh atau paling aman)
			var spawn_pos = Vector2i(999, 999)
			
			for zone in grid.p2_spawn_zones:
				if not grid.units_on_board.has(zone):
					spawn_pos = zone
					break # Ambil spawn zone kosong pertama ketemu
			
			if spawn_pos != Vector2i(999, 999):
				grid.spawn_unit_by_id(card_id, spawn_pos, 2)
			else:
				print("AI tidak punya tempat spawn!")
		
		recruits_remaining -= 1
		await get_tree().create_timer(0.5).timeout
	
	end_turn()

# Dipanggil oleh tombol SKIP atau setelah Unit bergerak
func skip_action_phase():
	print("Action selesai/di-skip. Masuk Fase Recruit.")
	start_recruit_phase()

# --- LOGIKA RECRUITMENT ---
#func start_recruit_phase():
	## 1. Cek apakah tim sudah penuh (5 orang)?
	#var my_unit_count = count_units(current_turn)
	#if my_unit_count >= 5:
		#print("Tim Penuh (5 Unit). Skip Recruit.")
		#end_turn()
		#return
#
	## 2. Tentukan jatah rekrut
	#recruits_remaining = 1
	#
	## ATURAN KHUSUS: Player 2 di Turn pertamanya dapat 2 kartu
	#if current_turn == 2 and p2_first_turn_bonus:
		#recruits_remaining = 2
		#p2_first_turn_bonus = false # Bonus hangus setelah dipakai
		#print("BONUS P2: Dapat rekrut 2 kartu!")
	#
	#open_recruit_ui()

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
