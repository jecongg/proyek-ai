extends Node
class_name AIBrain

# Struktur data sederhana untuk simulasi
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
const INF = 1000000.0 # Ubah jadi float biar aman

# Referensi ke GridManager
var grid_manager : Node 

# Konstanta Arah (Untuk kalkulasi surround)
const DIRECTIONS = [
	Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
	Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
]

func _init(_grid_manager):
	grid_manager = _grid_manager

# --- FUNGSI UTAMA ---
func get_best_move(current_board: Dictionary, ai_player_id: int):
	var start_time = Time.get_ticks_msec()
	
	# 1. Clone Board
	var virtual_board = _clone_board(current_board)
	
	# 2. Get Moves
	var possible_moves = _get_all_possible_moves(virtual_board, ai_player_id)
	
	# Jika tidak ada gerakan legal, kembalikan null
	if possible_moves.is_empty():
		return null
	
	# 3. Minimax dengan Alpha-Beta Pruning
	var best_eval = -INF
	var best_move = null
	var alpha = -INF
	var beta = INF
	
	# Mengacak urutan move agar AI tidak terlalu deterministik jika nilai sama
	possible_moves.shuffle()
	
	for move in possible_moves:
		var next_board = _apply_move(virtual_board, move)
		var eval = _minimax(next_board, MAX_DEPTH - 1, alpha, beta, false, ai_player_id)
		
		if eval > best_eval:
			best_eval = eval
			best_move = move
			
		alpha = max(alpha, eval)
		if beta <= alpha:
			break 
			
	print("AI Thought: ", Time.get_ticks_msec() - start_time, "ms | Moves: ", possible_moves.size(), " | Eval: ", best_eval)
	return best_move

func _minimax(board: Dictionary, depth: int, alpha: float, beta: float, is_maximizing: bool, ai_id: int) -> float:
	# Cek Game Over dulu sebelum depth
	var winner = _check_winner(board)
	if winner != 0:
		if winner == ai_id: return INF + depth # Menang lebih cepat lebih baik
		else: return -INF - depth # Kalah lebih lambat lebih baik
	
	if depth == 0:
		return _evaluate_board(board, ai_id)
	
	var enemy_id = 1 if ai_id == 2 else 2
	var current_turn = ai_id if is_maximizing else enemy_id
	
	var moves = _get_all_possible_moves(board, current_turn)
	
	if moves.is_empty():
		return _evaluate_board(board, ai_id) # Stuck? Evaluasi posisi sekarang
	
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

# --- STATIC EVALUATION FUNCTION (Updated) ---
func _evaluate_board(board: Dictionary, ai_id: int) -> float:
	var score = 0.0
	var enemy_id = 1 if ai_id == 2 else 2
	
	var my_leader_pos = Vector2i(999, 999)
	var enemy_leader_pos = Vector2i(999, 999)
	
	# 1. Temukan Lokasi Leader
	for coord in board:
		var u = board[coord]
		if u.id == "LEADER":
			if u.owner_id == ai_id: my_leader_pos = coord
			else: enemy_leader_pos = coord
	
	# Safety Check (Harusnya kecover di _check_winner, tapi jaga2)
	if my_leader_pos == Vector2i(999, 999): return -INF
	if enemy_leader_pos == Vector2i(999, 999): return INF
	
	# 2. Analisa Unit per Unit
	for coord in board:
		var unit = board[coord]
		var is_mine = (unit.owner_id == ai_id)
		var multiplier = 1 if is_mine else -1
		
		# A. Material Score (Berdasarkan Tier List ai_value)
		score += unit.data.ai_value * 10 * multiplier
		
		# B. Logic Spesifik Unit
		if is_mine:
			# Agresi: Dekatkan ke Leader Musuh
			var dist_to_enemy = _hex_distance(coord, enemy_leader_pos)
			
			if unit.data.is_assassin:
				if dist_to_enemy == 1: score += 900 # MENANG! (Hampir)
				else: score -= dist_to_enemy * 5 # Assassin harus ngejar
				
			elif unit.data.is_archer:
				# Archer bagus kalau sejajar lurus (Jarak 2 atau 3)
				if _is_in_line(coord, enemy_leader_pos) and dist_to_enemy <= 3:
					score += 50
					
			elif unit.data.is_protector:
				# Protector bagus kalau dekat Leader sendiri
				var dist_to_self = _hex_distance(coord, my_leader_pos)
				if dist_to_self == 1: score += 30
				
			else:
				# Unit biasa: Semakin dekat musuh semakin menekan
				score -= dist_to_enemy * 1.5
				
		else: # Unit Musuh
			# Defensif: Penalti jika musuh dekat Leader kita
			var dist_to_me = _hex_distance(coord, my_leader_pos)
			if dist_to_me == 1: score -= 100 # BAHAYA! Musuh nempel
			if dist_to_me == 2: score -= 20  # Waspada
			
			if unit.data.is_assassin and dist_to_me <= 2:
				score -= 500 # SANGAT BAHAYA (Assassin musuh dekat)

	# 3. Analisa Posisi Leader (Capture & Surround Pressure)
	
	# A. Ancaman Capture (Berapa musuh nempel Leader?)
	var enemies_near_me = _count_adjacent_enemies(board, my_leader_pos, ai_id)
	var allies_near_enemy = _count_adjacent_enemies(board, enemy_leader_pos, enemy_id)
	
	# Kalau sudah ada 1 musuh nempel, bahaya banget (karena tinggal 1 lagi buat capture)
	if enemies_near_me >= 1: score -= 200
	if allies_near_enemy >= 1: score += 200
	
	# B. Ancaman Surround (Berapa petak kosong tersisa?)
	var my_freedom = _count_free_spaces(board, my_leader_pos)
	var enemy_freedom = _count_free_spaces(board, enemy_leader_pos)
	
	# Semakin sedikit ruang gerak, semakin buruk (skor turun drastis)
	score -= (6 - my_freedom) * 15 
	score += (6 - enemy_freedom) * 15
	
	# Kalau tinggal 1 petak lagi terkurung -> PANIK
	if my_freedom <= 1: score -= 500
	if enemy_freedom <= 1: score += 500

	return score

# --- HELPER LOGIC ---

func _clone_board(original: Dictionary) -> Dictionary:
	var new_board = {}
	for coord in original:
		var u = original[coord]
		if u is Node: # Handle Node asli
			new_board[coord] = VirtualUnit.new(u.data.id, u.owner_id, u.data, u.has_moved)
		else: # Handle VirtualUnit
			new_board[coord] = VirtualUnit.new(u.id, u.owner_id, u.data, u.has_moved)
	return new_board

func _get_all_possible_moves(board: Dictionary, player_id: int) -> Array:
	var moves = []
	for coord in board:
		var unit = board[coord]
		if unit.owner_id == player_id and not unit.has_moved:
			# Gunakan logic gerak dari data karakter
			var raw_moves = unit.data.get_valid_moves(board, coord, unit.owner_id)
			for target in raw_moves:
				# Cek valid_tiles lewat GridManager
				if grid_manager.valid_tiles.has(target) and not board.has(target):
					moves.append({ "from": coord, "to": target })
	return moves

func _apply_move(board: Dictionary, move: Dictionary) -> Dictionary:
	var new_board = _clone_board(board)
	var unit = new_board[move["from"]]
	new_board.erase(move["from"])
	new_board[move["to"]] = unit
	unit.has_moved = true
	return new_board

# Simulasi cek pemenang sederhana (Hanya cek keberadaan Leader)
# (Untuk depth 3, simulasi capture penuh terlalu berat, jadi kita cek di eval saja)
func _check_winner(board: Dictionary) -> int:
	var p1_exists = false
	var p2_exists = false
	for u in board.values():
		if u.id == "LEADER":
			if u.owner_id == 1: p1_exists = true
			if u.owner_id == 2: p2_exists = true
	
	if not p1_exists: return 2
	if not p2_exists: return 1
	return 0

func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	var vec = a - b
	return (abs(vec.x) + abs(vec.y) + abs(vec.x + vec.y)) / 2

func _is_in_line(a: Vector2i, b: Vector2i) -> bool:
	# Cek apakah b berada di garis lurus dari a (6 arah hex)
	var diff = b - a
	# Di grid axial, segaris jika x=0, y=0, atau x+y=0
	return diff.x == 0 or diff.y == 0 or (diff.x + diff.y) == 0

func _count_adjacent_enemies(board: Dictionary, center: Vector2i, my_id: int) -> int:
	var count = 0
	for d in DIRECTIONS:
		var neighbor = center + d
		if board.has(neighbor):
			if board[neighbor].owner_id != my_id:
				count += 1
	return count

func _count_free_spaces(board: Dictionary, center: Vector2i) -> int:
	var free = 0
	for d in DIRECTIONS:
		var neighbor = center + d
		# Cek valid tile dan kosong
		if grid_manager.valid_tiles.has(neighbor) and not board.has(neighbor):
			free += 1
	return free
