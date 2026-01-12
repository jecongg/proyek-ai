extends Node2D

# --- KONFIGURASI ---
@export var hex_size : float = 268.5
@export var y_stretch : float = 0.356
@export var grid_offset : Vector2 = Vector2(-2, -1)
@export var tooltip_ui : Control

# --- DATA ---
var valid_tiles = {}
var unit_scene = preload("res://Unit.tscn")
var units_on_board = {} 

# --- ZONA & LEADER ---
var p1_spawn_zones = []
var p2_spawn_zones = []
var p1_leader_start : Vector2i
var p2_leader_start : Vector2i

# --- LOGIC GAMEPLAY ---
var is_skill_mode : bool = false
var valid_skill_targets : Array = []
var selected_unit_coord : Vector2i = Vector2i(999, 999) 
var valid_moves_current : Array = [] 

@onready var skill_btn = $"../UILayer/BtnSkill"

const DIRECTIONS = [
	Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
	Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
]

func _ready():
	setup_board_map()
	queue_redraw()

func setup_board_map():
	valid_tiles.clear()
	
	add_column(3, -6, -3)
	add_column(2, -5, -1)
	add_column(1, -4, 1)
	add_column(0, -3, 3)
	add_column(-1, -1, 4) 
	add_column(-2, 1, 5) 
	add_column(-3, 3, 6)
	
	p1_leader_start = Vector2i(-3, 6)
	p2_leader_start = Vector2i(3, -6)
	
	p1_spawn_zones = [Vector2i(-3, 3), Vector2i(-3, 4), Vector2i(-3, 5), Vector2i(-3, 6), Vector2i(-2, 5), Vector2i(-1, 4), Vector2i(0, 3)]
	p2_spawn_zones = [Vector2i(3, -3), Vector2i(3, -4), Vector2i(3, -5), Vector2i(3, -6), Vector2i(2, -5), Vector2i(1, -4), Vector2i(0, -3)]

func add_column(q, r_start, r_end):
	for r in range(r_start, r_end + 1):
		valid_tiles[Vector2i(q, r)] = true

func is_spawn_zone(coord: Vector2i, player_id: int) -> bool:
	if player_id == 1: return coord in p1_spawn_zones
	else: return coord in p2_spawn_zones

func spawn_unit_by_id(id_string: String, coords: Vector2i, owner_id: int):
	var data = CardDB.get_unit_data(id_string)
	if data == null: return

	if not valid_tiles.has(coords) or units_on_board.has(coords):
		print("Error: Tile tidak valid atau penuh!")
		return
	
	var new_unit = unit_scene.instantiate()
	add_child(new_unit)
	new_unit.position = hex_to_pixel(coords)
	new_unit.setup(data, coords, owner_id)
	
	units_on_board[coords] = new_unit
	if id_string != "LEADER" and id_string != "CUB":
		CardDB.taken_units.append(id_string)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_mouse = get_local_mouse_position()
		var hex_coord = pixel_to_hex(local_mouse)
		var game_manager = $"../GameManager"
		
		if not valid_tiles.has(hex_coord):
			deselect_unit()
			return

		if game_manager.current_state == game_manager.State.RECRUIT_PLACE:
			game_manager.try_place_recruit(hex_coord)
			return

		if game_manager.current_state == game_manager.State.ACTION_PHASE:
			handle_action_input(hex_coord, game_manager.current_turn)

func handle_action_input(clicked_coord: Vector2i, current_player: int):
	if units_on_board.has(clicked_coord):
		var unit = units_on_board[clicked_coord]
		if unit.owner_id == current_player:
			if not unit.has_moved:
				select_unit(clicked_coord, unit)
			else:
				print("Unit exhausted.")
		else:
			if is_skill_mode and clicked_coord in valid_skill_targets:
				execute_skill_on(clicked_coord)
			else:
				deselect_unit()
	
	else:
		if is_skill_mode and clicked_coord in valid_skill_targets:
			execute_skill_on(clicked_coord)
		
		elif clicked_coord in valid_moves_current and not is_skill_mode:
			move_selected_unit_to(clicked_coord)
			
		else:
			deselect_unit()

func select_unit(coord: Vector2i, unit):
	selected_unit_coord = coord
	is_skill_mode = false
	
	var moves = unit.data.get_valid_moves(units_on_board, coord, unit.owner_id)
	valid_moves_current.clear()
	for m in moves:
		if valid_tiles.has(m) and not units_on_board.has(m):
			valid_moves_current.append(m)
	
	var silenced = is_unit_silenced(coord, unit.owner_id)

	if unit.data.has_active_skill and not silenced:
		skill_btn.visible = true
		skill_btn.text = "USE SKILL"
		skill_btn.modulate = Color.WHITE
	else:
		skill_btn.visible = false
		if silenced and unit.data.has_active_skill:
			print("Unit ini terkena efek Jailer! Skill dikunci.")
	
	if tooltip_ui:
		tooltip_ui.show_info(unit.data)
 
	queue_redraw()

func deselect_unit():
	selected_unit_coord = Vector2i(999, 999)
	valid_moves_current.clear()
	valid_skill_targets.clear()
	is_skill_mode = false
	skill_btn.visible = false
	
	if tooltip_ui:
		tooltip_ui.hide_info() 
		
	queue_redraw()
	
func toggle_skill_mode():
	if selected_unit_coord == Vector2i(999, 999): return
	
	is_skill_mode = !is_skill_mode
	
	if is_skill_mode:
		skill_btn.modulate = Color.RED
		skill_btn.text = "CANCEL SKILL"
		
		var unit = units_on_board[selected_unit_coord]
		var raw_targets = unit.data.get_skill_targets(units_on_board, selected_unit_coord, unit.owner_id)
		
		valid_skill_targets.clear()
		for t in raw_targets:
			if valid_tiles.has(t):
				valid_skill_targets.append(t)
		
		if valid_skill_targets.is_empty():
			print("Tidak ada target skill yang valid!")
			
	else:
		skill_btn.modulate = Color.WHITE
		skill_btn.text = "USE SKILL"
		valid_skill_targets.clear()

	queue_redraw()

func move_selected_unit_to(target_coord: Vector2i):
	execute_move(selected_unit_coord, target_coord)

func execute_skill_on(target_coord: Vector2i):
	var unit = units_on_board[selected_unit_coord]
	var success = unit.data.resolve_skill(units_on_board, selected_unit_coord, target_coord, self)
	
	if success:
		unit.mark_as_moved() 
		deselect_unit()
		$"../GameManager".on_action_performed()

func execute_move(from_coord: Vector2i, to_coord: Vector2i):
	if not units_on_board.has(from_coord): return
	
	var unit = units_on_board[from_coord]
	
	# 1. Update Data
	units_on_board.erase(from_coord)
	units_on_board[to_coord] = unit
	
	# 2. Visual
	var pixel_target = hex_to_pixel(to_coord)
	var tween = create_tween()
	tween.tween_property(unit, "position", pixel_target, 0.5)
	
	# 3. Status
	unit.grid_pos = to_coord
	unit.mark_as_moved() 
	
	check_nemesis_trigger(unit) 
	
	# 4. Win Condition
	check_win_condition(unit.owner_id)
	
	# 5. Selesai
	deselect_unit()
	$"../GameManager".on_action_performed()

func force_move_unit(from: Vector2i, to: Vector2i) -> bool:
	if not units_on_board.has(from): return false
	var unit = units_on_board[from]

	var current_player = $"../GameManager".current_turn
	var is_enemy_action = (unit.owner_id != current_player)
	
	if is_unit_protected(from, is_enemy_action):
		print("AKSI DIBLOKIR PROTECTOR!")
		return false 

	units_on_board.erase(from)
	units_on_board[to] = unit
	unit.grid_pos = to
	
	var px = hex_to_pixel(to)
	var tween = create_tween()
	tween.tween_property(unit, "position", px, 0.3).set_trans(Tween.TRANS_BOUNCE)
	
	if unit.data.id != "NEMESIS":
		check_nemesis_trigger(unit)
	
	check_win_condition(1)
	check_win_condition(2)
	
	return true 

func swap_units(pos_a: Vector2i, pos_b: Vector2i):
	if not units_on_board.has(pos_a) or not units_on_board.has(pos_b): return
	
	var unit_a = units_on_board[pos_a]
	var unit_b = units_on_board[pos_b]
	var current_player = $"../GameManager".current_turn
	
	var a_is_enemy = (unit_a.owner_id != current_player)
	if is_unit_protected(pos_a, a_is_enemy):
		print("Swap Gagal! Unit A dilindungi Protector.")
		return

	var b_is_enemy = (unit_b.owner_id != current_player)
	if is_unit_protected(pos_b, b_is_enemy):
		print("Swap Gagal! Unit B dilindungi Protector.")
		return
	
	units_on_board[pos_a] = unit_b
	units_on_board[pos_b] = unit_a
	unit_a.grid_pos = pos_b
	unit_b.grid_pos = pos_a

	var px_a = hex_to_pixel(pos_a)
	var px_b = hex_to_pixel(pos_b)
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(unit_a, "position", px_b, 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(unit_b, "position", px_a, 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	unit_a.scale = Vector2(1.2, 1.2) 
	unit_b.scale = Vector2(1.2, 1.2)
	tween.tween_property(unit_a, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(unit_b, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	check_win_condition(1)
	check_win_condition(2)

func check_win_condition(attacker_id: int):
	var game_manager = $"../GameManager"
	if game_manager.current_state == game_manager.State.GAME_OVER: return

	var enemy_id = 1 if attacker_id == 2 else 2
	var enemy_leader_pos = Vector2i(999, 999)
	
	for coord in units_on_board:
		var unit = units_on_board[coord]
		if unit.data.id == "LEADER" and unit.owner_id == enemy_id:
			enemy_leader_pos = coord
			break
	
	if enemy_leader_pos == Vector2i(999, 999): return 

	var enemy_adj_count = 0
	for dir in DIRECTIONS:
		var neighbor = enemy_leader_pos + dir
		if units_on_board.has(neighbor):
			var unit = units_on_board[neighbor]
			if unit.owner_id == attacker_id:
				if unit.data.id == "ASSASSIN":
					game_manager.trigger_game_over(attacker_id)
					return
				if not unit.data.is_archer and unit.data.can_capture_leader: 
					enemy_adj_count += 1
		
		var snipe_pos = enemy_leader_pos + (dir * 2)
		if units_on_board.has(snipe_pos):
			var u = units_on_board[snipe_pos]
			if u.owner_id == attacker_id and u.data.is_archer:
				enemy_adj_count += 1

	if enemy_adj_count >= 2:
		game_manager.trigger_game_over(attacker_id)
		return

	var is_surrounded = true
	for dir in DIRECTIONS:
		var neighbor = enemy_leader_pos + dir
		if valid_tiles.has(neighbor) and not units_on_board.has(neighbor):
			is_surrounded = false 
			break
	
	if is_surrounded:
		game_manager.trigger_game_over(attacker_id)


func hex_to_pixel(hex: Vector2i) -> Vector2:
	var x = hex_size * sqrt(3) * (hex.x + hex.y / 2.0)
	var y = (hex_size * 3.0 / 2.0 * hex.y) * y_stretch
	return Vector2(x, y) + grid_offset

func pixel_to_hex(local_pos: Vector2) -> Vector2i:
	local_pos -= grid_offset
	var adjusted_y = local_pos.y / y_stretch
	var q = (sqrt(3)/3 * local_pos.x - 1.0/3 * adjusted_y) / hex_size
	var r = (2.0/3 * adjusted_y) / hex_size
	return hex_round(Vector2(q, r))

func hex_round(hex: Vector2) -> Vector2i:
	var s = -hex.x - hex.y
	var q = round(hex.x)
	var r = round(hex.y)
	var s_round = round(s)
	var q_diff = abs(q - hex.x)
	var r_diff = abs(r - hex.y)
	var s_diff = abs(s_round - s)
	if q_diff > r_diff and q_diff > s_diff: q = -r - s_round
	elif r_diff > s_diff: r = -q - s_round
	return Vector2i(q, r)

func get_neighbors(coords: Vector2i) -> Array:
	var result = []
	for d in DIRECTIONS:
		result.append(coords + d)
	return result

func highlight_spawn_zones(player_id: int, active: bool):
	queue_redraw()

func _draw():
	# Mode SKILL (MERAH)
	if is_skill_mode:
		for target in valid_skill_targets:
			var px = hex_to_pixel(target)
			draw_circle(px, 20, Color(1, 0.2, 0.2, 0.6))
			draw_arc(px, 20, 0, TAU, 32, Color.WHITE, 2.0)
			
	# Mode MOVE (HIJAU)
	else:
		for move in valid_moves_current:
			var px = hex_to_pixel(move)
			draw_circle(px, 15, Color(0, 1, 0, 0.5))
		
	# Unit Terpilih (KUNING)
	if valid_tiles.has(selected_unit_coord):
		var px = hex_to_pixel(selected_unit_coord)
		draw_circle(px, 20, Color(1, 1, 0, 0.3))

func is_unit_silenced(unit_pos: Vector2i, owner_id: int) -> bool:
	# Cek 6 tetangga
	var neighbors = get_neighbors(unit_pos)
	for n in neighbors:
		if units_on_board.has(n):
			var neighbor_unit = units_on_board[n]
			# Jika tetangga adalah MUSUH dan dia adalah JAILER
			if neighbor_unit.owner_id != owner_id and neighbor_unit.data.is_jailer:
				return true # Terkena Silence!
	return false

func is_unit_protected(unit_pos: Vector2i, initiator_is_enemy: bool) -> bool:
	if not initiator_is_enemy: return false 
	
	if not units_on_board.has(unit_pos): return false
	var unit = units_on_board[unit_pos]
	
	if unit.data.id == "PROTECTOR": 
		return true
	
	var neighbors = get_neighbors(unit_pos)
	for n in neighbors:
		if units_on_board.has(n):
			var neighbor_unit = units_on_board[n]
			if neighbor_unit.owner_id == unit.owner_id and neighbor_unit.data.id == "PROTECTOR":
				return true
				
	return false

func check_nemesis_trigger(moved_unit):
	if moved_unit.data.id != "LEADER": return
	
	var leader_owner = moved_unit.owner_id
	var nemesis_owner = 1 if leader_owner == 2 else 2
	
	var nemesis_unit = null
	var nemesis_pos = Vector2i.ZERO
	for coord in units_on_board:
		var u = units_on_board[coord]
		if u.data.id == "NEMESIS" and u.owner_id == nemesis_owner:
			nemesis_unit = u
			nemesis_pos = coord
			break
	
	if nemesis_unit == null: return 

	var target_pos = moved_unit.grid_pos
	
	var current_path_pos = nemesis_pos
	var steps_taken = 0
	
	for i in range(2): 
		var next_step = get_best_step_towards(current_path_pos, target_pos, nemesis_pos)
		
		if next_step != current_path_pos:
			force_move_unit_no_trigger(current_path_pos, next_step)
			
			current_path_pos = next_step
			
			await get_tree().create_timer(0.2).timeout 
		else:
			break 
	
	if steps_taken > 0:
		print("NEMESIS: Mengejar Leader musuh sebanyak ", steps_taken, " langkah.")
		force_move_unit_no_trigger(nemesis_pos, current_path_pos)

func get_best_step_towards(current: Vector2i, target: Vector2i, origin: Vector2i) -> Vector2i:
	var best_pos = current
	var min_dist = get_hex_distance(current, target)
	
	for dir in DIRECTIONS:
		var check = current + dir
		
		if valid_tiles.has(check) and not units_on_board.has(check) and check != origin:
			var dist = get_hex_distance(check, target)
			if dist < min_dist:
				min_dist = dist
				best_pos = check
				
	return best_pos

func get_hex_distance(a: Vector2i, b: Vector2i) -> int:
	var vec = a - b
	return (abs(vec.x) + abs(vec.y) + abs(vec.x + vec.y)) / 2

func force_move_unit_no_trigger(from: Vector2i, to: Vector2i):
	if not units_on_board.has(from): return
	var unit = units_on_board[from]
	
	units_on_board.erase(from)
	units_on_board[to] = unit
	unit.grid_pos = to
	
	var px = hex_to_pixel(to)
	var tween = create_tween()
	tween.tween_property(unit, "position", px, 0.4)
	
	check_win_condition(1)
	check_win_condition(2)
