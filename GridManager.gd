extends Node2D

# --- KONFIGURASI ---
# Angka Kalibrasi Final Kamu
@export var hex_size : float = 268.5
@export var y_stretch : float = 268.5
@export var grid_offset : Vector2 = Vector2(-2, -1)

# --- DATA GRID ---
# Dictionary untuk menyimpan tile yang valid
# Key: Vector2i(q, r) -> Koordinat
# Value: null (atau nanti bisa diisi data Unit)
var valid_tiles = {}

# Reference Unit (Testing)
@export var test_unit : Sprite2D 

var p1_spawn_zones = [] # Area rekrut Player 1 (Bawah)
var p2_spawn_zones = [] # Area rekrut Player 2 (Atas)
var p1_leader_start : Vector2i
var p2_leader_start : Vector2i

func setup_board_map():
	valid_tiles.clear()
	
	# --- SISI KANAN (Tetap) ---
	add_column(3, -6, -3)
	add_column(2, -5, -1)
	add_column(1, -4, 1)
	add_column(0, -3, 3) # Tengah
	
	# --- SISI KIRI (DIREVISI) ---
	
	# Kolom -1: 
	# Tadi mulai dari -2 (salah), sekarang mulai dari -1 (benar)
	# Range: (-1, -1) sampai (-1, 4)
	add_column(-1, -1, 4) 
	
	# Kolom -2:
	# Tadi mulai dari 0 (salah), sekarang mulai dari 1 (benar)
	# Range: (-2, 1) sampai (-2, 5)
	add_column(-2, 1, 5) 
	
	# Kolom -3 (Tetap)
	add_column(-3, 3, 6)
	
	print("Total Tile Valid: ", valid_tiles.size())
	
	# Set Leader Start (Biasanya paling tengah di baris belakang)
	p1_leader_start = Vector2i(-3, 6)  # Contoh: Tengah Bawah
	p2_leader_start = Vector2i(3, -6) # Contoh: Tengah Atas
	
	# Set Zona Rekrut (Area di sekitar Leader atau baris belakang)
	# Masukkan koordinat manual yang dianggap "Sisi Papan Anda"
	p1_spawn_zones = [Vector2i(-3, 3), Vector2i(-3, 4),Vector2i(-3, 5), Vector2i(-3, 6), Vector2i(-2, 5), Vector2i(-1, 4), Vector2i(0, 3)] # Isi koordinat baris bawah
	p2_spawn_zones = [Vector2i(3, -3), Vector2i(3, -4),Vector2i(3, -5), Vector2i(3, -6), Vector2i(2, -5), Vector2i(1, -4), Vector2i(0, -3)] # Isi koordinat baris bawah


# Fungsi Helper untuk mengecek apakah tile ini adalah zona spawn player tertentu
func is_spawn_zone(coord: Vector2i, player_id: int) -> bool:
	if player_id == 1:
		return coord in p1_spawn_zones
	else:
		return coord in p2_spawn_zones

# Helper function biar nulisnya pendek
func add_column(q, r_start, r_end):
	for r in range(r_start, r_end + 1): # +1 biar angka terakhir masuk
		valid_tiles[Vector2i(q, r)] = true

# --- FUNGSI 2: GAMBAR VISUAL ---
func _draw():
	# Sekarang kita HANYA menggambar jika koordinat ada di dalam 'valid_tiles'
	# Loop manual range besar (untuk scanning), atau loop dictionary-nya langsung.
	
	# Cara Efisien: Loop langsung isi dictionary valid_tiles
	for hex in valid_tiles.keys():
		var pixel_pos = hex_to_pixel(hex)
		
		# Gambar Titik Merah (Visualisasi Tile Valid)
		draw_circle(pixel_pos, 5, Color.RED)
		
		# Gambar Koordinat (Opsional, matikan kalau sudah hafal)
		draw_string(ThemeDB.fallback_font, pixel_pos + Vector2(0, -15), str(hex), HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.BLACK)

# --- UNIT MANAGEMENT ---
# Ambil Cetakan Kue (Unit.tscn)
var unit_scene = preload("res://Unit.tscn")

# Database posisi unit
# Key: Vector2i(q, r) -> Value: Node Unit
var units_on_board = {} 

func _ready():
	setup_board_map()
	
	# COBA SPAWN ACROBAT BUAT PLAYER 1
	spawn_unit_by_id("ACROBAT", Vector2i(0, 0), 1)
	
	# COBA SPAWN ACROBAT BUAT PLAYER 2 (Harusnya GAGAL karena unik)
	spawn_unit_by_id("ACROBAT", Vector2i(0, -1), 2) 

func spawn_unit_by_id(id_string: String, coords: Vector2i, owner_id: int):
	# 1. Minta Data ke Database
	var data = CardDB.get_unit_data(id_string)
	
	# 2. Cek apakah boleh diambil?
	if data == null:
		print("Gagal Spawn: Unit ", id_string, " tidak tersedia atau sudah diambil.")
		return
		
	# 3. Tandai sudah diambil (Mark as Taken)
	CardDB.taken_units.append(id_string)
	
	# 4. Proses Spawn Visual (Sama seperti sebelumnya)
	var new_unit = unit_scene.instantiate()
	add_child(new_unit)
	new_unit.position = hex_to_pixel(coords)
	new_unit.setup(data, coords, owner_id)
	units_on_board[coords] = new_unit

# --- FUNGSI SPAWN DINAMIS ---
func spawn_unit(type_name: String, coords: Vector2i, owner_id: int):
	# 1. Cek apakah koordinat valid & kosong?
	if not valid_tiles.has(coords):
		print("Error: Tile tidak valid!")
		return
	if units_on_board.has(coords):
		print("Error: Tile sudah ada isinya!")
		return

	# 2. Ciptakan Instance Baru
	var new_unit = unit_scene.instantiate()
	
	# 3. Masukkan ke dalam Scene Tree (Sebagai anak Board)
	add_child(new_unit)
	
	# 4. Atur Posisi Pixel & Data
	new_unit.position = hex_to_pixel(coords)
	new_unit.setup(type_name, coords, owner_id) 
	
	# 5. Catat di Buku Data
	units_on_board[coords] = new_unit
	print("Unit ", type_name, " lahir di ", coords)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_mouse = get_local_mouse_position()
		var hex_coord = pixel_to_hex(local_mouse)
		
		if valid_tiles.has(hex_coord):
			# Cek apakah kita klik unit?
			if units_on_board.has(hex_coord):
				print("Kamu klik unit: ", units_on_board[hex_coord].unit_type)
				# Nanti di sini logic select unit
			else:
				print("Kamu klik tile kosong: ", hex_coord)
				# Nanti di sini logic pindah (move)

# --- RUMUS MATEMATIKA (JANGAN DIUBAH LAGI) ---
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
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s_round
	elif r_diff > s_diff:
		r = -q - s_round
	return Vector2i(q, r)
	
	# Cek apakah Player ID ini MENANG?
func check_win_condition(attacker_id: int):
	var enemy_id = 1
	if attacker_id == 1: enemy_id = 2
	
	# 1. Cari Posisi Leader Musuh
	var enemy_leader_pos = Vector2i.ZERO
	var leader_found = false
	
	for coord in units_on_board:
		var unit = units_on_board[coord]
		if unit.data.id == "LEADER" and unit.owner_id == enemy_id:
			enemy_leader_pos = coord
			leader_found = true
			break
	
	if not leader_found:
		return # Belum ada leader (awal game)
		
	# 2. Cek Kondisi CAPTURE (2 Musuh di sebelah Leader)
	var neighbors = get_neighbors(enemy_leader_pos)
	var enemy_count_around = 0
	
	for n in neighbors:
		if units_on_board.has(n):
			var unit = units_on_board[n]
			if unit.owner_id == attacker_id:
				enemy_count_around += 1
				# Logic Assassin: Kalau yang sebelah adalah Assassin, langsung menang?
				if unit.data.id == "ASSASSIN":
					print("MENANG! Assassin membunuh Leader!")
					return
	
	if enemy_count_around >= 2:
		print("MENANG! Kondisi CAPTURE terpenuhi!")
		return

	# 3. Cek Kondisi SURROUND (Leader Terkepung, tidak bisa gerak)
	var free_space = 0
	for n in neighbors:
		# Petak disebut 'Bebas' jika:
		# a. Ada di dalam papan (Valid Tile)
		# b. DAN Tidak ada unit di sana
		if valid_tiles.has(n) and not units_on_board.has(n):
			free_space += 1
	
	if free_space == 0:
		print("MENANG! Kondisi SURROUND terpenuhi!")
		return

const DIRECTIONS = [
	Vector2i(0, -1),  # Atas Kiri
	Vector2i(1, -2),  # Atas Kanan
	Vector2i(1, -1),  # Kanan
	Vector2i(0, 1),   # Bawah Kanan
	Vector2i(-1, 2),  # Bawah Kiri
	Vector2i(-1, 1)   # Kiri
]

func get_neighbors(coords: Vector2i) -> Array:
	var result = []
	for d in DIRECTIONS:
		result.append(coords + d)
	return result
