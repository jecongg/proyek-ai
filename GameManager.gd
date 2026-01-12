extends Node

enum State { ACTION_PHASE, RECRUIT_SELECT, RECRUIT_PLACE, GAME_OVER }

var current_state = State.ACTION_PHASE
var current_turn = 1
var p2_first_turn_bonus = true 
var recruits_remaining = 0 
var selected_card_index : int = -1 
var selected_card_id = ""
var pending_cub_spawn : bool = false 

@onready var grid = $"../Board"
@export var recruit_ui : Control
@export var in_game_menu : Control 
@onready var info_label = $"../UILayer/InfoLabel"
var ai_brain : AIBrain

func _ready():
	SoundManager.play_music("game") 
	ai_brain = AIBrain.new(grid)
	ai_brain.MAX_DEPTH = GlobalSettings.ai_depth 
	add_child(ai_brain)
	
	CardDB.initialize_deck() 
	
	if recruit_ui:
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
	
	info_label.text = "TURN PLAYER " + str(current_turn)
	
	for unit in grid.units_on_board.values():
		if unit.owner_id == current_turn:
			unit.reset_turn_state()
			
	print("Giliran Player ", current_turn, " Dimulai.")
	
	if current_turn == 2:
		info_label.text += " (AI SEDANG BERPIKIR...)"
		await get_tree().create_timer(1.0).timeout
		perform_ai_action_phase()

func perform_ai_action_phase():
	if current_state == State.GAME_OVER: return 
	
	print("AI Sedang berpikir untuk langkah berikutnya...")
	
	var best_move = ai_brain.get_best_move(grid.units_on_board, current_turn)
	
	if best_move != null:
		print("AI Memilih Gerak: ", best_move["from"], " -> ", best_move["to"])
		grid.execute_move(best_move["from"], best_move["to"])
	else:
		print("AI Selesai Bergerak (Tidak ada langkah lagi).")
		skip_action_phase()

func on_action_performed():
	if current_state == State.GAME_OVER: return
	await get_tree().create_timer(0.6).timeout
	
	if current_turn == 2:
		perform_ai_action_phase()

# --- RECRUITMENT ---
func skip_action_phase():
	print("Action selesai/di-skip. Masuk Fase Recruit.")
	start_recruit_phase()

func start_recruit_phase():
	if count_total_cards(current_turn) >= 5:
		print("Sudah punya 5 kartu (Leader + 4 Ally). Lewati rekrut.")
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
	
	if pending_cub_spawn:
		grid.spawn_unit_by_id("CUB", coords, current_turn)
		print("Cub berhasil diletakkan.")
		
		pending_cub_spawn = false
		
		recruit_ui.set_buttons_active(true) 
		# ----------------------------------
		
		finish_recruit_step()
		
	else:
		var final_card_id = CardDB.pick_card_from_market(selected_card_index)
		if final_card_id == "": return

		grid.spawn_unit_by_id(final_card_id, coords, current_turn)
		
		if final_card_id == "HERMIT":
			print("Hermit diletakkan. Silakan letakkan CUB!")
			pending_cub_spawn = true 
			
			recruit_ui.update_visuals() 
			
			recruit_ui.set_buttons_active(false)
			
			return 
			
		recruit_ui.update_visuals()
		finish_recruit_step()
		
func finish_recruit_step():
	grid.highlight_spawn_zones(current_turn, false)
	recruits_remaining -= 1
	selected_card_index = -1
	selected_card_id = ""
	
	if recruits_remaining > 0:
		if count_total_cards(current_turn) >= 5:
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
			
			var spawn_pos_1 = find_ai_spawn_pos()
			if spawn_pos_1 != Vector2i(999, 999):
				grid.spawn_unit_by_id(card_id, spawn_pos_1, 2)
				
				if card_id == "HERMIT":
					await get_tree().create_timer(0.5).timeout 
					var spawn_pos_2 = find_ai_spawn_pos() 
					
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

func count_total_cards(player_id) -> int:
	var total = 0
	for unit in grid.units_on_board.values():
		if unit.owner_id == player_id:
			if unit.data.id != "CUB":
				total += 1
	return total

func find_ai_spawn_pos() -> Vector2i:
	for zone in grid.p2_spawn_zones:
		if not grid.units_on_board.has(zone):
			return zone
	return Vector2i(999, 999)
	
func trigger_game_over(winner_id: int):
	if current_state == State.GAME_OVER: return
	
	current_state = State.GAME_OVER
	print("!!! GAME OVER !!! Pemenang: Player ", winner_id)
	
	# PANGGIL MENU GAME OVER
	if in_game_menu:
		in_game_menu.open_game_over_menu(winner_id)
	
	# Matikan UI Recruit
	recruit_ui.close_market()
