extends Node

enum State { ACTION_PHASE, RECRUIT_SELECT, RECRUIT_PLACE }

var current_state = State.ACTION_PHASE
var current_turn = 1
var p2_first_turn_bonus = true 
var recruits_remaining = 0 
var selected_card_index : int = -1 
var selected_card_id = ""

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
	var best_move = ai_brain.get_best_move(grid.units_on_board, current_turn)
	if best_move != null:
		print("AI Memilih Gerak: ", best_move["from"], " -> ", best_move["to"])
		grid.execute_move(best_move["from"], best_move["to"])
	else:
		print("AI Skip Action.")
		skip_action_phase()

func on_action_performed():
	await get_tree().create_timer(0.6).timeout
	if current_turn == 2:
		skip_action_phase()

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
		
	# 1. PICK SEKARANG (Hapus dari market & Ganti baru)
	# Karena CardDB sudah diperbaiki, dia TIDAK akan menandai taken dulu.
	var final_card_id = CardDB.pick_card_from_market(selected_card_index)
	
	if final_card_id == "": return

	# 2. SPAWN (GridManager akan menandai taken)
	grid.spawn_unit_by_id(final_card_id, coords, current_turn)
	grid.highlight_spawn_zones(current_turn, false)
	
	# 3. UPDATE UI
	recruit_ui.update_visuals()
	
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
		var best_cost = -1
		
		# AI Pilih Kartu Termahal
		for i in range(3): # Hardcode 3 slot
			var card_id = CardDB.get_market_card_id(i) # Pake get, jangan market_cards langsung
			if card_id == "": continue
			
			if CardDB.library.has(card_id):
				var d = CardDB.library[card_id].new()
				if d.cost > best_cost:
					best_cost = d.cost
					best_idx = i
		
		if best_idx != -1:
			recruit_ui.highlight_selected_card(best_idx) 
			await get_tree().create_timer(1.0).timeout
			
			var card_id = CardDB.pick_card_from_market(best_idx)
			print("AI Membeli Unit: ", card_id)
			
			var spawn_pos = Vector2i(999, 999)
			for zone in grid.p2_spawn_zones:
				if not grid.units_on_board.has(zone):
					spawn_pos = zone
					break 
			
			if spawn_pos != Vector2i(999, 999):
				grid.spawn_unit_by_id(card_id, spawn_pos, 2)
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
