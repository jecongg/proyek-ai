extends Node2D

# --- KONFIGURASI ---
@export var hex_size : float = 268.5
@export var y_stretch : float = 0.356 # Angka presisi hasil riset kita
@export var grid_offset : Vector2 = Vector2(-2, -1)

# --- DATA GRID ---
var valid_tiles = {}
var unit_scene = preload("res://Unit.tscn")
var units_on_board = {} 

# --- ZONA ---
var p1_spawn_zones = []
var p2_spawn_zones = []
var p1_leader_start : Vector2i
var p2_leader_start : Vector2i

var is_skill_mode : bool = false
var valid_skill_targets : Array = []
@onready var skill_btn = $"../UILayer/BtnSkill"

# --- LOGIC SELEKSI & GERAK ---
var selected_unit_coord : Vector2i = Vector2i(999, 999) # Koordinat unit yg dipilih
var valid_moves_current : Array = [] # Daftar kotak tujuan yg boleh diinjak

# Konstanta Arah (Sesuai Skewed Grid kita)
const DIRECTIONS = [
	Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
	Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
]

func _ready():
	setup_board_map()
	queue_redraw()

# --- SETUP PETA ---
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

# --- SPAWN LOGIC ---
func spawn_unit_by_id(id_string: String, coords: Vector2i, owner_id: int):
	var data = CardDB.get_unit_data(id_string)
	if data == null: return # Gagal ambil data

	if not valid_tiles.has(coords) or units_on_board.has(coords):
		print("Error: Tile tidak valid atau penuh!")
		return
	
	var new_unit = unit_scene.instantiate()
	add_child(new_unit)
	new_unit.position = hex_to_pixel(coords)
	new_unit.setup(data, coords, owner_id)
	
	units_on_board[coords] = new_unit
	if id_string != "LEADER": # Leader tidak ditandai taken
		CardDB.taken_units.append(id_string)

# --- INPUT HANDLING (PENTING) ---
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_mouse = get_local_mouse_position()
		var hex_coord = pixel_to_hex(local_mouse)
		var game_manager = $"../GameManager"
		
		if not valid_tiles.has(hex_coord):
			deselect_unit()
			return

		# KASUS 1: FASE RECRUIT (Letakkan Unit)
		if game_manager.current_state == game_manager.State.RECRUIT_PLACE:
			game_manager.try_place_recruit(hex_coord)
			return

		# KASUS 2: FASE ACTION (Gerakkan Unit)
		if game_manager.current_state == game_manager.State.ACTION_PHASE:
			handle_action_input(hex_coord, game_manager.current_turn)

# --- LOGIKA GERAKAN ---
func handle_action_input(clicked_coord: Vector2i, current_player: int):
	# A. KLIK UNIT SENDIRI (Select)
	if units_on_board.has(clicked_coord):
		var unit = units_on_board[clicked_coord]
		if unit.owner_id == current_player:
			if not unit.has_moved:
				select_unit(clicked_coord, unit)
			else:
				print("Unit exhausted.")
		else:
			# KLIK MUSUH?
			# Claw Launcher sekarang targetnya TILE KOSONG, bukan Unit Musuh langsung.
			# Tapi karakter lain (seperti Bruiser) mungkin targetnya Musuh.
			# Jadi kita cek dua-duanya.
			if is_skill_mode and clicked_coord in valid_skill_targets:
				execute_skill_on(clicked_coord)
			else:
				deselect_unit()
	
	# B. KLIK TILE KOSONG
	else:
		# --- UPDATE DI SINI ---
		# Jika Skill Mode aktif DAN tile kosong ini adalah target valid (Indikator Merah)
		if is_skill_mode and clicked_coord in valid_skill_targets:
			execute_skill_on(clicked_coord)
		
		# Jika Move Mode (Hijau)
		elif clicked_coord in valid_moves_current and not is_skill_mode:
			move_selected_unit_to(clicked_coord)
			
		else:
			deselect_unit()
			
func select_unit(coord: Vector2i, unit):
	selected_unit_coord = coord
	is_skill_mode = false # Reset mode ke Move dulu
	
	# 1. Hitung Move biasa
	var moves = unit.data.get_valid_moves(units_on_board, coord, unit.owner_id)
	valid_moves_current.clear()
	for m in moves:
		if valid_tiles.has(m) and not units_on_board.has(m):
			valid_moves_current.append(m)
	
	# 2. Update Tombol Skill
	if unit.data.has_active_skill:
		skill_btn.visible = true
		skill_btn.text = "USE SKILL"
		skill_btn.modulate = Color.WHITE
	else:
		skill_btn.visible = false
		
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
		skill_btn.modulate = Color.RED # Indikator tombol merah
		skill_btn.text = "CANCEL SKILL" # Ubah teks biar jelas
		
		# Hitung Target Skill
		var unit = units_on_board[selected_unit_coord]
		valid_skill_targets = unit.data.get_skill_targets(units_on_board, selected_unit_coord, unit.owner_id)
		
		if valid_skill_targets.is_empty():
			print("Tidak ada target skill yang valid!")
	else:
		skill_btn.modulate = Color.WHITE
		skill_btn.text = "USE SKILL"
		valid_skill_targets.clear()
		
	queue_redraw() # Wajib panggil ini untuk update gambar

# --- FUNGSI EKSEKUSI SKILL ---
func execute_skill_on(target_coord: Vector2i):
	var unit = units_on_board[selected_unit_coord]
	
	# Panggil fungsi di CharacterData
	var success = unit.data.resolve_skill(units_on_board, selected_unit_coord, target_coord, self)
	
	if success:
		unit.mark_as_moved() # Pakai skill hitungannya 1 aksi
		deselect_unit()
		$"../GameManager".on_action_performed()

# --- HELPER PINDAH PAKSA (Untuk Claw, Bruiser, dll) ---
func force_move_unit(from: Vector2i, to: Vector2i):
	if not units_on_board.has(from): return
	var unit = units_on_board[from]
	
	# Update Data
	units_on_board.erase(from)
	units_on_board[to] = unit
	unit.grid_pos = to
	
	# Animasi Cepat
	var px = hex_to_pixel(to)
	var tween = create_tween()
	tween.tween_property(unit, "position", px, 0.3).set_trans(Tween.TRANS_BOUNCE)
	
	# Cek Win Condition (Siapa tau ketarik ke sebelah Assassin)
	# Kita cek untuk kedua pihak
	check_win_condition(1)
	check_win_condition(2)

func move_selected_unit_to(target_coord: Vector2i):
	execute_move(selected_unit_coord, target_coord)
	#var unit = units_on_board[selected_unit_coord]
	#
	## 1. Update Data Dictionary
	#units_on_board.erase(selected_unit_coord)
	#units_on_board[target_coord] = unit
	#
	## 2. Update Visual (Animasi)
	#var pixel_target = hex_to_pixel(target_coord)
	#var tween = create_tween()
	#tween.tween_property(unit, "position", pixel_target, 0.2)
	#
	## 3. Update Data Unit
	#unit.grid_pos = target_coord
	#unit.mark_as_moved() # Tandai sudah gerak
	#
	## 4. Cek Win Condition
	#check_win_condition(unit.owner_id)
	#
	## 5. Reset Seleksi
	#deselect_unit()

func check_win_condition(attacker_id: int):
	var game_manager = $"../GameManager"
	
	# Kalau game sudah over, jangan cek lagi
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
	
	var neighbors = get_neighbors(enemy_leader_pos)
	
	# Cek CAPTURE
	var enemy_count_around = 0
	for n in neighbors:
		if units_on_board.has(n):
			var unit = units_on_board[n]
			if unit.owner_id == attacker_id:
				enemy_count_around += 1
				if unit.data.is_assassin: 
					print("MENANG! Assassin Kill.")
					game_manager.trigger_game_over(attacker_id) # <--- PANGGIL INI
					return
	
	if enemy_count_around >= 2:
		print("MENANG! Capture Condition.")
		game_manager.trigger_game_over(attacker_id)
		return

	# Cek SURROUND
	var free_space = 0
	for n in neighbors:
		if valid_tiles.has(n) and not units_on_board.has(n):
			free_space += 1
	
	if free_space == 0:
		print("MENANG! Surround Condition.")
		game_manager.trigger_game_over(attacker_id)

# --- RUMUS MATEMATIKA ---
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
	# Nanti bisa tambah visual di sini jika mau
	queue_redraw()

# --- UPDATE FUNGSI GAMBAR (VISUAL) ---
func _draw():
	# 1. Visualisasi Debug Grid (Opsional - boleh dicomment)
	# for hex in valid_tiles.keys():
	# 	draw_circle(hex_to_pixel(hex), 5, Color.RED)
	
	# 2. LOGIKA PEMISAH (HIJAU VS MERAH)
	if is_skill_mode:
		for target in valid_skill_targets:
			var px = hex_to_pixel(target)
			# Gambar Lingkaran Merah
			draw_circle(px, 20, Color(1, 0.2, 0.2, 0.6))
			
			# Tambah Outline Putih biar kelihatan ini "Target"
			draw_arc(px, 20, 0, TAU, 32, Color.WHITE, 2.0)
			
	else:
		# --- MODE GERAK: GAMBAR HIJAU ---
		for move in valid_moves_current:
			var px = hex_to_pixel(move)
			draw_circle(px, 15, Color(0, 1, 0, 0.5))
		
	# 3. Highlight Unit Terpilih (Kuning) - Selalu muncul
	if valid_tiles.has(selected_unit_coord):
		var px = hex_to_pixel(selected_unit_coord)
		draw_circle(px, 20, Color(1, 1, 0, 0.3))
		
func execute_move(from_coord: Vector2i, to_coord: Vector2i):
	if not units_on_board.has(from_coord): return
	
	var unit = units_on_board[from_coord]
	
	# 1. Update Data Dictionary
	units_on_board.erase(from_coord)
	units_on_board[to_coord] = unit
	
	# 2. Update Visual (Animasi)
	var pixel_target = hex_to_pixel(to_coord)
	var tween = create_tween()
	tween.tween_property(unit, "position", pixel_target, 0.5) # Agak lambat biar kelihatan
	
	# 3. Update Data Unit
	unit.grid_pos = to_coord
	unit.mark_as_moved() 
	
	# 4. Cek Win Condition
	check_win_condition(unit.owner_id)
	
	# 5. Seleksi ulang (hanya visual)
	deselect_unit()
	
	# 6. Lapor ke GameManager bahwa aksi selesai (untuk trigger fase recruit atau next move)
	$"../GameManager".on_action_performed()
