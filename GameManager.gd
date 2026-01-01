extends Node

enum State { ACTION_PHASE, RECRUIT_SELECT, RECRUIT_PLACE }

var current_state = State.ACTION_PHASE
var current_turn = 1
var p2_first_turn_bonus = true 
var recruits_remaining = 0 
var selected_card_index : int = -1 
var selected_card_id = ""
var pending_cub_spawn : bool = false 

@onready var grid = $"../Board"
@export var recruit_ui : Control 
@onready var info_label = $"../UILayer/InfoLabel"
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

func start_turn(player_id):
	current_turn = player_id
	current_state = State.ACTION_PHASE
	
	info_label.text = "GILIRAN PLAYER " + str(current_turn)
	
	# Reset unit state (warna)
	for unit in grid.units_on_board.values():
		if unit.owner_id == current_turn:
			unit.reset_turn_state()
			
	print("Giliran Player ", current_turn, " Dimulai.")
	
	if current_turn == 2: # AI
		info_label.text += " (AI SEDANG BERPIKIR...)"
		await get_tree().create_timer(1.0).timeout
		perform_ai_action_phase()

func perform_ai_action_phase():
	# Cek apakah masih ada unit yang BISA gerak?
	# (AIBrain sudah otomatis memfilter unit yang 'has_moved' == true)
	
	print("AI Sedang berpikir untuk langkah berikutnya...")
	
	# Minta otak AI mencari langkah terbaik untuk unit yang TERSISA
	var best_move = ai_brain.get_best_move(grid.units_on_board, current_turn)
	
	if best_move != null:
		print("AI Memilih Gerak: ", best_move["from"], " -> ", best_move["to"])
		grid.execute_move(best_move["from"], best_move["to"])
		# Setelah ini, GridManager akan memanggil 'on_action_performed'
	else:
		# Jika return null, artinya:
		# 1. Semua unit sudah gerak (exhausted).
		# 2. ATAU Unit yang sisa tidak punya langkah aman (Minimax nilai jelek).
		print("AI Selesai Bergerak (Tidak ada langkah lagi).")
		skip_action_phase() # BARU PINDAH KE RECRUIT

func on_action_performed():
	# Tunggu animasi visual selesai
	await get_tree().create_timer(0.6).timeout
	
	if current_turn == 2:
		# --- PERUBAHAN PENTING DI SINI ---
		# Jangan langsung skip_action_phase()!
		# Panggil lagi fungsi berpikir AI untuk mencari langkah unit selanjutnya.
		perform_ai_action_phase()

# --- RECRUITMENT ---
func skip_action_phase():
	print("Action selesai/di-skip. Masuk Fase Recruit.")
	start_recruit_phase()

func start_recruit_phase():
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
		do_ai_recruit()

func open_recruit_ui():
	current_state = State.RECRUIT_SELECT
	recruit_ui.show_market()
	print("Silakan pilih kartu...")

# PILIH KARTU (PLAYER)
func _on_card_picked_from_ui(index):
	selected_card_index = index
	# Preview ID kartu (tanpa menghapusnya dari market dulu)
	selected_card_id = CardDB.get_market_card_id(index)
	current_state = State.RECRUIT_PLACE
	
	grid.highlight_spawn_zones(current_turn, true)
	recruit_ui.highlight_selected_card(index) 
	print("Kartu terpilih: ", selected_card_id)

# TARUH KARTU (PLAYER)
func try_place_recruit(coords: Vector2i):
	if current_state != State.RECRUIT_PLACE: return
	
	if grid.units_on_board.has(coords):
		print("Tile penuh!")
		return
	if not grid.is_spawn_zone(coords, current_turn):
		print("Bukan Zona Spawn Anda!")
		return
		
	# --- LOGIKA CABANG ---
	
	if pending_cub_spawn:
		# KASUS A: MELETAKKAN CUB (Langkah 2)
		grid.spawn_unit_by_id("CUB", coords, current_turn)
		print("Cub berhasil diletakkan.")
		
		pending_cub_spawn = false
		
		# --- PERBAIKAN 1: BUKA KUNCI UI ---
		recruit_ui.set_buttons_active(true) 
		# ----------------------------------
		
		finish_recruit_step()
		
	else:
		# KASUS B: MELETAKKAN KARTU NORMAL (Langkah 1)
		var final_card_id = CardDB.pick_card_from_market(selected_card_index)
		if final_card_id == "": return

		grid.spawn_unit_by_id(final_card_id, coords, current_turn)
		
		if final_card_id == "HERMIT":
			print("Hermit diletakkan. Silakan letakkan CUB!")
			pending_cub_spawn = true 
			
			recruit_ui.update_visuals() # Refresh gambar jadi baru
			
			# --- PERBAIKAN 2: KUNCI UI ---
			# Supaya player TIDAK BISA klik kartu lain sebelum naruh Cub
			recruit_ui.set_buttons_active(false)
			# -----------------------------
			
			return 
			
		# Kartu biasa (bukan Hermit)
		recruit_ui.update_visuals()
		finish_recruit_step()
		
func finish_recruit_step():
	grid.highlight_spawn_zones(current_turn, false)
	recruits_remaining -= 1
	selected_card_index = -1
	selected_card_id = ""
	
	if recruits_remaining > 0:
		if count_units(current_turn) >= 5:
			end_turn()
		else:
			print("Masih ada jatah rekrut!")
			current_state = State.RECRUIT_SELECT
			recruit_ui.update_visuals() 
	else:
		end_turn()

# AI RECRUIT
func do_ai_recruit():
	recruit_ui.show_market()
	await get_tree().create_timer(0.5).timeout
	
	while recruits_remaining > 0:
		var best_idx = -1
		var best_value = -1
		
		# (Logic AI memilih kartu SAMA SEPERTI SEBELUMNYA)
		for i in range(3): 
			var card_id = CardDB.get_market_card_id(i)
			if card_id == "": continue
			if CardDB.library.has(card_id):
				var d = CardDB.library[card_id].new()
				if d.ai_value > best_value:
					best_value = d.ai_value
					best_idx = i
		
		if best_idx != -1:
			recruit_ui.highlight_selected_card(best_idx) 
			await get_tree().create_timer(1.0).timeout
			
			var card_id = CardDB.pick_card_from_market(best_idx)
			print("AI Membeli Unit: ", card_id)
			
			# 1. Cari Posisi untuk UNIT UTAMA
			var spawn_pos_1 = find_ai_spawn_pos()
			if spawn_pos_1 != Vector2i(999, 999):
				grid.spawn_unit_by_id(card_id, spawn_pos_1, 2)
				
				# 2. KHUSUS HERMIT: Cari Posisi ke-2 untuk CUB
				if card_id == "HERMIT":
					await get_tree().create_timer(0.5).timeout # Jeda dikit
					var spawn_pos_2 = find_ai_spawn_pos() # Cari tempat kosong lagi
					
					if spawn_pos_2 != Vector2i(999, 999):
						print("AI Meletakkan CUB")
						grid.spawn_unit_by_id("CUB", spawn_pos_2, 2)
				
				recruit_ui.update_visuals()
		
		recruits_remaining -= 1
		await get_tree().create_timer(0.5).timeout
	
	end_turn()

func end_turn():
	recruit_ui.close_market() 
	var next_p = 1
	if current_turn == 1: next_p = 2
	start_turn(next_p)

func count_units(player_id) -> int:
	var count = 0
	for unit in grid.units_on_board.values():
		if unit.owner_id == player_id:
			count += 1
	return count

func find_ai_spawn_pos() -> Vector2i:
	for zone in grid.p2_spawn_zones:
		if not grid.units_on_board.has(zone):
			return zone
	return Vector2i(999, 999) # Penuh
