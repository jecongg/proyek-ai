extends Node2D

# Variabel untuk menyimpan state permainan
var board_state = [[null, null, null], [null, null, null], [null, null, null]]
var current_turn = "X"
var game_over = false

# Tekstur untuk X dan O yang akan kita muat dari file aset
var texture_x = preload("res://assets/x.png")
var texture_o = preload("res://assets/o.png")

# Referensi ke InfoLabel agar mudah diakses
@onready var info_label = $Label


# Fungsi ini berjalan sekali saat game dimulai
func _ready():
	start_new_game()

# Fungsi untuk mereset permainan
func start_new_game():
	board_state = [[null, null, null], [null, null, null], [null, null, null]]
	current_turn = "X"
	game_over = false
	info_label.text = "Giliran: " + current_turn
	# Hapus semua pion (X dan O) dari permainan sebelumnya
	for child in get_children():
		if child.name == "Piece":
			child.queue_free()

# Fungsi ini mendeteksi semua jenis input (mouse, keyboard, dll)
func _input(event):
	# Kita hanya peduli pada klik kiri mouse, dan hanya jika game belum berakhir
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if game_over:
			# Jika game sudah selesai, klik di mana saja untuk memulai lagi
			start_new_game()
		else:
			# Dapatkan posisi klik mouse dan konversi ke koordinat grid (0, 1, atau 2)
			var mouse_pos = get_local_mouse_position()
			var grid_x = int(mouse_pos.x / 100)
			var grid_y = int(mouse_pos.y / 100)
			
			# Cek apakah klik berada di dalam papan (0-2) dan sel tersebut kosong
			if grid_x >= 0 and grid_x <= 2 and grid_y >= 0 and grid_y <= 2:
				if board_state[grid_y][grid_x] == null:
					place_piece(grid_x, grid_y)

# Fungsi untuk menempatkan pion di papan
func place_piece(x, y):
	# 1. Update data logika kita
	board_state[y][x] = current_turn
	
	# 2. Buat pion baru secara visual (Sprite2D)
	var new_piece = Sprite2D.new()
	new_piece.name = "Piece" # Beri nama agar mudah dihapus nanti
	if current_turn == "X":
		new_piece.texture = texture_x
	else:
		new_piece.texture = texture_o
	
	# Posisikan pion di tengah sel grid
	new_piece.position = Vector2(x * 100 + 50, y * 100 + 50)
	add_child(new_piece)
	
	# 3. Cek apakah ada pemenang
	if check_for_win():
		info_label.text = "Pemenang: " + current_turn + "! Klik untuk main lagi."
		game_over = true
	else:
		# 4. Ganti giliran
		if current_turn == "X":
			current_turn = "O"
		else:
			current_turn = "X"
		info_label.text = "Giliran: " + current_turn


# Fungsi untuk mengecek semua kondisi kemenangan
func check_for_win():
	# Cek baris horizontal
	for y in range(3):
		if board_state[y][0] == current_turn and board_state[y][1] == current_turn and board_state[y][2] == current_turn:
			return true
	
	# Cek kolom vertikal
	for x in range(3):
		if board_state[0][x] == current_turn and board_state[1][x] == current_turn and board_state[2][x] == current_turn:
			return true
	
	# Cek diagonal
	if board_state[0][0] == current_turn and board_state[1][1] == current_turn and board_state[2][2] == current_turn:
		return true
	if board_state[0][2] == current_turn and board_state[1][1] == current_turn and board_state[2][0] == current_turn:
		return true
		
	return false # Tidak ada yang menang
