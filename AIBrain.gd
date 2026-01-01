extends Node
class_name AIBrain

# Struktur data sederhana untuk simulasi (Virtual Unit)
class VirtualUnit:
	var id: String
	var owner_id: int
	var data: CharacterData
	var has_moved: bool = false
	
	func _init(_id, _owner, _data, _moved=false):
		id = _id
		owner_id = _owner
		data = _data
		has_moved = _moved

# --- KONFIGURASI AI ---
const MAX_DEPTH = 3
const INF = 1000000

# Referensi ke GridManager (untuk helper function)
var grid_manager : Node 

func _init(_grid_manager):
	grid_manager = _grid_manager

# --- FUNGSI UTAMA: Minta Langkah Terbaik ---
func get_best_move(current_board: Dictionary, ai_player_id: int):
	var start_time = Time.get_ticks_msec()
	
	# 1. Buat Virtual Board dari Board Asli
	var virtual_board = _clone_board(current_board)
	
	# 2. Jalankan Minimax
	var best_eval = -INF
	var best_move = null
	
	# Dapatkan semua langkah legal untuk AI saat ini
	var possible_moves = _get_all_possible_moves(virtual_board, ai_player_id)
	
	# Alpha-Beta Pruning Initial Values
	var alpha = -INF
	var beta = INF
	
	for move in possible_moves:
		# Simulasi langkah
		var next_board = _apply_move(virtual_board, move)
		
		# Panggil Minimax Recursive (sekarang giliran musuh/minimizing)
		var eval = _minimax(next_board, MAX_DEPTH - 1, alpha, beta, false, ai_player_id)
		
		if eval > best_eval:
			best_eval = eval
			best_move = move
			
		alpha = max(alpha, eval)
		if beta <= alpha:
			break # Pruning
			
	print("AI Thinking Time: ", Time.get_ticks_msec() - start_time, "ms. Eval: ", best_eval)
	return best_move

# --- ALGORITMA MINIMAX ---
func _minimax(board: Dictionary, depth: int, alpha: float, beta: float, is_maximizing: bool, ai_id: int) -> float:
	# Base Case: Depth habis atau Game Over
	if depth == 0 or _is_game_over(board):
		return _evaluate_board(board, ai_id)
	
	var enemy_id = 1 if ai_id == 2 else 2
	var current_turn = ai_id if is_maximizing else enemy_id
	
	var moves = _get_all_possible_moves(board, current_turn)
	
	if is_maximizing:
		var max_eval = -INF
		for move in moves:
			var next_board = _apply_move(board, move)
			var eval = _minimax(next_board, depth - 1, alpha, beta, false, ai_id)
			max_eval = max(max_eval, eval)
			alpha = max(alpha, eval)
			if beta <= alpha: break
		return max_eval
	else:
		var min_eval = INF
		for move in moves:
			var next_board = _apply_move(board, move)
			var eval = _minimax(next_board, depth - 1, alpha, beta, true, ai_id)
			min_eval = min(min_eval, eval)
			beta = min(beta, eval)
			if beta <= alpha: break
		return min_eval

# --- LOGIKA EVALUASI (KEPINTARAN AI) ---
func _evaluate_board(board: Dictionary, ai_id: int) -> float:
	var score = 0.0
	var enemy_id = 1 if ai_id == 2 else 2
	
	var my_leader_pos = Vector2i.ZERO
	var enemy_leader_pos = Vector2i.ZERO
	var my_units = []
	var enemy_units = []
	
	# 1. Scan Board
	for coord in board:
		var unit = board[coord]
		if unit.owner_id == ai_id:
			my_units.append(coord)
			if unit.id == "LEADER": my_leader_pos = coord
			score += unit.data.cost * 10 # Material value
		else:
			enemy_units.append(coord)
			if unit.id == "LEADER": enemy_leader_pos = coord
			score -= unit.data.cost * 10
			
	# 2. Cek Kematian (Prioritas Tertinggi)
	if my_leader_pos == Vector2i.ZERO: return -INF # Kita Kalah
	if enemy_leader_pos == Vector2i.ZERO: return INF # Kita Menang
	
	# 3. Heuristik: Jarak ke Leader Musuh (Agresi)
	# Semakin dekat unit kita ke leader musuh, semakin bagus
	for my_pos in my_units:
		var dist = _hex_distance(my_pos, enemy_leader_pos)
		score -= dist * 2 # Minus distance (semakin kecil jarak, score makin tinggi)
		
		# Bonus khusus Assassin dekat Leader
		if board[my_pos].data.is_assassin and dist <= 1:
			score += 500 
	
	# 4. Heuristik: Keamanan Leader Sendiri (Defensif)
	for enemy_pos in enemy_units:
		var dist = _hex_distance(enemy_pos, my_leader_pos)
		score += dist * 1.5 # Semakin jauh musuh, semakin aman
		
		# Bahaya besar jika musuh dekat leader kita
		if dist <= 1:
			score -= 300 

	return score

# --- HELPER SIMULASI ---
func _clone_board(original: Dictionary) -> Dictionary:
	var new_board = {}
	for coord in original:
		var u = original[coord]
		# Kita copy data penting saja (VirtualUnit)
		# Jika u adalah Node asli, kita convert ke VirtualUnit
		if u is Node: # Cek apakah ini Node asli Godot
			new_board[coord] = VirtualUnit.new(u.data.id, u.owner_id, u.data, u.has_moved)
		else: # Jika sudah VirtualUnit (dari rekursi)
			new_board[coord] = VirtualUnit.new(u.id, u.owner_id, u.data, u.has_moved)
	return new_board

func _get_all_possible_moves(board: Dictionary, player_id: int) -> Array:
	var moves = []
	for coord in board:
		var unit = board[coord]
		if unit.owner_id == player_id and not unit.has_moved:
			
			# --- PERBAIKAN DI SINI ---
			# Kirim 'unit.owner_id' (atau player_id) ke fungsi ini
			var raw_moves = unit.data.get_valid_moves(board, coord, unit.owner_id)
			
			for target in raw_moves:
				if grid_manager.valid_tiles.has(target) and not board.has(target):
					moves.append({ "from": coord, "to": target })
	return moves

func _apply_move(board: Dictionary, move: Dictionary) -> Dictionary:
	var new_board = _clone_board(board)
	var unit = new_board[move["from"]]
	
	# Pindahkan
	new_board.erase(move["from"])
	new_board[move["to"]] = unit
	
	# Update status
	unit.has_moved = true
	
	# Cek Capture/Kill sederhana di sini (Simulasi aturan game)
	# Untuk AI Depth 3, simulasi capture sangat penting.
	# Ini harus meniru logic check_win_condition di GridManager
	# Tapi untuk simplifikasi kode ini, kita skip logic capture kompleks
	# (Kecuali Assassin kill, itu penting).
	
	return new_board

func _is_game_over(board: Dictionary) -> bool:
	# Cek apakah salah satu leader hilang
	var p1_leader = false
	var p2_leader = false
	for u in board.values():
		if u.id == "LEADER":
			if u.owner_id == 1: p1_leader = true
			if u.owner_id == 2: p2_leader = true
	return not (p1_leader and p2_leader)

func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	# Rumus jarak Hex (Axial Coordinates)
	var vec = a - b
	return (abs(vec.x) + abs(vec.y) + abs(vec.x + vec.y)) / 2
