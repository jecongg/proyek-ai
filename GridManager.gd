extends Node2D

# --- KONFIGURASI ---
@export var hex_size : float = 268.5
@export var y_stretch : float = 0.356
@export var grid_offset : Vector2 = Vector2(-2, -1)

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

# ==========================================
# 1. SETUP & SPAWN
# ==========================================
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
	if id_string != "LEADER":
		CardDB.taken_units.append(id_string)

# ==========================================
# 2. INPUT HANDLING
# ==========================================
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_mouse = get_local_mouse_position()
		var hex_coord = pixel_to_hex(local_mouse)
		var game_manager = $"../GameManager"
		
		# Cek apakah klik di luar papan (kecuali sedang Skill Mode mungkin targetnya UI, tapi ini aman)
		if not valid_tiles.has(hex_coord):
			deselect_unit()
			return

		# FASE RECRUIT
		if game_manager.current_state == game_manager.State.RECRUIT_PLACE:
			game_manager.try_place_recruit(hex_coord)
			return

		# FASE ACTION
		if game_manager.current_state == game_manager.State.ACTION_PHASE:
			handle_action_input(hex_coord, game_manager.current_turn)

func handle_action_input(clicked_coord: Vector2i, current_player: int):
	# A. KLIK UNIT SENDIRI -> SELECT
	if units_on_board.has(clicked_coord):
		var unit = units_on_board[clicked_coord]
		if unit.owner_id == current_player:
			if not unit.has_moved:
				select_unit(clicked_coord, unit)
			else:
				print("Unit exhausted.")
		else:
			# KLIK MUSUH (Hanya valid jika Skill Mode dan itu target skill)
			if is_skill_mode and clicked_coord in valid_skill_targets:
				execute_skill_on(clicked_coord)
			else:
				deselect_unit()
	
	# B. KLIK TILE KOSONG ATAU TARGET SKILL
	else:
		# Prioritas 1: Skill Mode (Target Merah)
		if is_skill_mode and clicked_coord in valid_skill_targets:
			execute_skill_on(clicked_coord)
		
		# Prioritas 2: Move Mode (Target Hijau)
		elif clicked_coord in valid_moves_current and not is_skill_mode:
			move_selected_unit_to(clicked_coord)
			
		else:
			deselect_unit()

# ==========================================
# 3. SELECTION & MODES
# ==========================================
func select_unit(coord: Vector2i, unit):
	selected_unit_coord = coord
	is_skill_mode = false
	
	# Hitung Moves (Hijau)
	var moves = unit.data.get_valid_moves(units_on_board, coord, unit.owner_id)
	valid_moves_current.clear()
	for m in moves:
		if valid_tiles.has(m) and not units_on_board.has(m):
			valid_moves_current.append(m)
	
	# --- LOGIKA JAILER ---
	var silenced = is_unit_silenced(coord, unit.owner_id)
	
	# Tampilkan Tombol Skill HANYA JIKA punya skill DAN TIDAK SILENCED
	if unit.data.has_active_skill and not silenced:
		skill_btn.visible = true
		skill_btn.text = "USE SKILL"
		skill_btn.modulate = Color.WHITE
	else:
		skill_btn.visible = false
		if silenced and unit.data.has_active_skill:
			print("Unit ini terkena efek Jailer! Skill dikunci.")
		
	queue_redraw()

func deselect_unit():
	selected_unit_coord = Vector2i(999, 999)
	valid_moves_current.clear()
	valid_skill_targets.clear()
	is_skill_mode = false
	skill_btn.visible = false
	queue_redraw()
	
func toggle_skill_mode():
	if selected_unit_coord == Vector2i(999, 999): return
	
	is_skill_mode = !is_skill_mode
	
	if is_skill_mode:
		skill_btn.modulate = Color.RED
		skill_btn.text = "CANCEL SKILL"
		
		var unit = units_on_board[selected_unit_coord]
		var raw_targets = unit.data.get_skill_targets(units_on_board, selected_unit_coord, unit.owner_id)
		
		# Filter hanya target yang ada di papan
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

# ==========================================
# 4. EXECUTION (MOVE / SKILL / SWAP)
# ==========================================

# Eksekusi Gerak Normal (Jalan Kaki)
func move_selected_unit_to(target_coord: Vector2i):
	# Panggil fungsi general execute_move
	execute_move(selected_unit_coord, target_coord)

# Eksekusi Skill (Dipanggil saat klik target Merah)
func execute_skill_on(target_coord: Vector2i):
	var unit = units_on_board[selected_unit_coord]
	var success = unit.data.resolve_skill(units_on_board, selected_unit_coord, target_coord, self)
	
	if success:
		unit.mark_as_moved() 
		deselect_unit()
		$"../GameManager".on_action_performed()

# Fungsi General Pindah Unit (Dipakai AI dan Player Move)
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
	
	# 4. Win Condition
	check_win_condition(unit.owner_id)
	
	# 5. Selesai
	deselect_unit()
	$"../GameManager".on_action_performed()

# Helper Pindah Paksa (Untuk Push/Pull Skill)
func force_move_unit(from: Vector2i, to: Vector2i):
	if not units_on_board.has(from): return
	var unit = units_on_board[from]
	
	units_on_board.erase(from)
	units_on_board[to] = unit
	unit.grid_pos = to
	
	var px = hex_to_pixel(to)
	var tween = create_tween()
	tween.tween_property(unit, "position", px, 0.3).set_trans(Tween.TRANS_BOUNCE)
	
	check_win_condition(1)
	check_win_condition(2)

# Helper Tukar Posisi (Untuk Illusionist)
func swap_units(pos_a: Vector2i, pos_b: Vector2i):
	if not units_on_board.has(pos_a) or not units_on_board.has(pos_b): return
		
	var unit_a = units_on_board[pos_a]
	var unit_b = units_on_board[pos_b]
	
	# Tukar Data
	units_on_board[pos_a] = unit_b
	units_on_board[pos_b] = unit_a
	unit_a.grid_pos = pos_b
	unit_b.grid_pos = pos_a
	
	# Animasi Silang
	var px_a = hex_to_pixel(pos_a)
	var px_b = hex_to_pixel(pos_b)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(unit_a, "position", px_b, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(unit_b, "position", px_a, 0.3).set_trans(Tween.TRANS_CUBIC)
	
	check_win_condition(1)
	check_win_condition(2)

# ==========================================
# 5. WIN CONDITION
# ==========================================
func check_win_condition(attacker_id: int):
	var game_manager = $"../GameManager"
	if game_manager.current_state == game_manager.State.GAME_OVER: return

	var enemy_id = 1
	if attacker_id == 1: enemy_id = 2
	
	var enemy_leader_pos = Vector2i.ZERO
	var leader_found = false
	
	for coord in units_on_board:
		var unit = units_on_board[coord]
		if unit.data.id == "LEADER" and unit.owner_id == enemy_id:
			enemy_leader_pos = coord
			leader_found = true
			break
	
	if not leader_found: return 
	
	var threat_count = 0
	
	# A. Cek Tetangga (Jarak 1)
	for dir in DIRECTIONS:
		var neighbor = enemy_leader_pos + dir
		if units_on_board.has(neighbor):
			var unit = units_on_board[neighbor]
			if unit.owner_id == attacker_id:
				if unit.data.is_assassin:
					print("MENANG! Assassin membunuh Leader.")
					game_manager.trigger_game_over(attacker_id)
					return
				
				# Archer tidak bisa capture kalau nempel
				if not unit.data.is_archer:
					threat_count += 1
	
	# B. Cek Archer Jauh (Jarak 2)
	for dir in DIRECTIONS:
		var snipe_pos = enemy_leader_pos + (dir * 2)
		if units_on_board.has(snipe_pos):
			var unit = units_on_board[snipe_pos]
			if unit.owner_id == attacker_id and unit.data.is_archer:
				print("Archer membidik Leader dari jauh!")
				threat_count += 1

	if threat_count >= 2:
		print("MENANG! Leader musuh ter-Capture.")
		game_manager.trigger_game_over(attacker_id)
		return

	# Cek Surround
	var free_space = 0
	var neighbors = get_neighbors(enemy_leader_pos)
	for n in neighbors:
		if valid_tiles.has(n) and not units_on_board.has(n):
			free_space += 1
	
	if free_space == 0:
		print("MENANG! Surround Condition.")
		game_manager.trigger_game_over(attacker_id)

# ==========================================
# 6. MATH & DRAWING
# ==========================================
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

# Cek apakah unit ini dilindungi PROTECTOR (Tidak bisa digeser Musuh)
# initiator_is_enemy: TRUE jika skill berasal dari musuh
func is_unit_protected(unit_pos: Vector2i, initiator_is_enemy: bool) -> bool:
	if not units_on_board.has(unit_pos): return false
	if not initiator_is_enemy: return false # Kalau teman sendiri yang geser (Brewmaster), boleh.
	
	var unit = units_on_board[unit_pos]
	
	# Cek 1: Apakah dia sendiri Protector?
	if unit.data.is_protector: return true
	
	# Cek 2: Apakah ada Protector teman di sebelahnya?
	var neighbors = get_neighbors(unit_pos)
	for n in neighbors:
		if units_on_board.has(n):
			var neighbor = units_on_board[n]
			# Jika tetangga adalah TEMAN dan dia PROTECTOR
			if neighbor.owner_id == unit.owner_id and neighbor.data.is_protector:
				return true
				
	return false
