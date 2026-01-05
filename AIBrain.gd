extends Node
class_name AIBrain

# Struktur data virtual
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
const INF = 1000000.0

# --- BOBOT NILAI (TUNING) ---
const SCORE_KILL_LEADER = 10000.0
const SCORE_CAPTURE_THREAT = 500.0
const SCORE_SURROUND_PANIC = 800.0
const SCORE_MATERIAL_MULTIPLIER = 15.0

const PENALTY_IN_JAILER_ZONE = 50.0       
const PENALTY_EXPOSED_TO_PULL = 150.0     
const PENALTY_EXPOSED_LEADER = 300.0      
const PENALTY_ARCHER_SNIPE = 200.0        

var grid_manager : Node 

const DIRECTIONS = [
	Vector2i(0, -1), Vector2i(1, -2), Vector2i(1, -1),
	Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-1, 1)
]

func _init(_grid_manager):
	grid_manager = _grid_manager

# --- FUNGSI UTAMA ---
func get_best_move(current_board: Dictionary, ai_player_id: int):
	var start_time = Time.get_ticks_msec()
	var virtual_board = _clone_board(current_board)
	var possible_moves = _get_all_possible_moves(virtual_board, ai_player_id)
	
	if possible_moves.is_empty(): return null
	
	var best_eval = -INF
	var best_move = null
	var alpha = -INF
	var beta = INF
	
	possible_moves.shuffle() 
	
	for move in possible_moves:
		var next_board = _apply_move(virtual_board, move)
		var eval = _minimax(next_board, MAX_DEPTH - 1, alpha, beta, false, ai_player_id)
		
		if eval > best_eval:
			best_eval = eval
			best_move = move
			
		alpha = max(alpha, eval)
		if beta <= alpha: break 
			
	print("AI Thought: ", Time.get_ticks_msec() - start_time, "ms | Eval: ", best_eval)
	return best_move

func _minimax(board: Dictionary, depth: int, alpha: float, beta: float, is_maximizing: bool, ai_id: int) -> float:
	var winner = _check_winner(board)
	if winner != 0:
		if winner == ai_id: return INF + depth
		else: return -INF - depth
	
	if depth == 0:
		return _evaluate_board(board, ai_id)
	
	var enemy_id = 1 if ai_id == 2 else 2
	var current_turn = ai_id if is_maximizing else enemy_id
	var moves = _get_all_possible_moves(board, current_turn)
	
	if moves.is_empty(): return _evaluate_board(board, ai_id)
	
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

# --- FUNGSI EVALUASI PINTAR ---
func _evaluate_board(board: Dictionary, ai_id: int) -> float:
	var score = 0.0
	var enemy_id = 1 if ai_id == 2 else 2
	
	var my_leader_pos = Vector2i(999, 999)
	var enemy_leader_pos = Vector2i(999, 999)
	
	var enemy_jailers = []
	var enemy_pullers = [] 
	var enemy_archers = []
	var my_units = []
	
	# 1. SCANNING AWAL
	for coord in board:
		var unit = board[coord]
		var is_mine = (unit.owner_id == ai_id)
		
		if unit.id == "LEADER":
			if is_mine: my_leader_pos = coord
			else: enemy_leader_pos = coord
		
		var val = unit.data.ai_value * SCORE_MATERIAL_MULTIPLIER
		if is_mine: 
			score += val
			my_units.append(coord)
		else: 
			score -= val
			if unit.data.is_jailer: enemy_jailers.append(coord)
			if unit.id == "ILLUSIONIST" or unit.id == "CLAW_LAUNCHER": enemy_pullers.append(coord)
			if unit.data.is_archer: enemy_archers.append(coord)

	if my_leader_pos == Vector2i(999, 999): return -INF
	if enemy_leader_pos == Vector2i(999, 999): return INF

	# 2. EVALUASI UNIT KITA
	for my_pos in my_units:
		var unit = board[my_pos]
		var is_leader = (unit.id == "LEADER")
		
		# A. CEK JAILER
		if unit.data.has_active_skill:
			for jailer_pos in enemy_jailers:
				if _hex_distance(my_pos, jailer_pos) == 1:
					score -= PENALTY_IN_JAILER_ZONE
		
		# B. CEK VISIBILITY
		for enemy_pos in enemy_pullers:
			if _is_visible_in_line(board, my_pos, enemy_pos):
				var penalty = PENALTY_EXPOSED_TO_PULL
				if is_leader: penalty = PENALTY_EXPOSED_LEADER 
				score -= penalty

		# C. POSISI STRATEGIS
		var dist_to_enemy_leader = _hex_distance(my_pos, enemy_leader_pos)
		
		if is_leader:
			score -= dist_to_enemy_leader * 2 
		else:
			score -= dist_to_enemy_leader * 1.5
			if unit.data.is_assassin and dist_to_enemy_leader == 1:
				score += SCORE_KILL_LEADER

	# 3. EVALUASI LEADER
	# A. Archer Musuh
	for archer_pos in enemy_archers:
		if _is_in_line(my_leader_pos, archer_pos) and _hex_distance(my_leader_pos, archer_pos) == 2:
			score -= PENALTY_ARCHER_SNIPE
			
	# B. Capture
	var enemies_near_me = _count_adjacent_enemies(board, my_leader_pos, ai_id)
	if enemies_near_me >= 1: score -= SCORE_CAPTURE_THREAT
	if enemies_near_me >= 2: score -= SCORE_KILL_LEADER 
	
	# C. Surround
	var my_freedom = _count_free_spaces(board, my_leader_pos)
	if my_freedom <= 1: score -= SCORE_SURROUND_PANIC
	
	# 4. AGRESIVITAS
	var allies_near_enemy = _count_adjacent_enemies(board, enemy_leader_pos, enemy_id)
	if allies_near_enemy >= 1: score += SCORE_CAPTURE_THREAT
	if allies_near_enemy >= 2: score += SCORE_KILL_LEADER 

	return score

# --- HELPER FUNCTIONS ---

func _clone_board(original: Dictionary) -> Dictionary:
	var new_board = {}
	for coord in original:
		var u = original[coord]
		if u is Node:
			new_board[coord] = VirtualUnit.new(u.data.id, u.owner_id, u.data, u.has_moved)
		else:
			new_board[coord] = VirtualUnit.new(u.id, u.owner_id, u.data, u.has_moved)
	return new_board

func _get_all_possible_moves(board: Dictionary, player_id: int) -> Array:
	var moves = []
	for coord in board:
		var unit = board[coord]
		if unit.owner_id == player_id and not unit.has_moved:
			var raw_moves = unit.data.get_valid_moves(board, coord, unit.owner_id)
			for target in raw_moves:
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

func _check_winner(board: Dictionary) -> int:
	var p1 = false
	var p2 = false
	for u in board.values():
		if u.id == "LEADER":
			if u.owner_id == 1: p1 = true
			if u.owner_id == 2: p2 = true
	if not p1: return 2
	if not p2: return 1
	return 0

func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	var vec = a - b
	return (abs(vec.x) + abs(vec.y) + abs(vec.x + vec.y)) / 2

func _is_in_line(a: Vector2i, b: Vector2i) -> bool:
	var diff = b - a
	return diff.x == 0 or diff.y == 0 or (diff.x + diff.y) == 0

func _is_visible_in_line(board: Dictionary, start: Vector2i, end: Vector2i) -> bool:
	if not _is_in_line(start, end): return false
	
	var dist = _hex_distance(start, end)
	if dist <= 1: return true 
	
	var dir = _get_direction(start, end)
	if dir == Vector2i.ZERO: return false # Tidak segaris (safety check)

	var check = start + dir
	while check != end:
		if board.has(check):
			return false 
		check += dir
		
	return true 

func _get_direction(from: Vector2i, to: Vector2i) -> Vector2i:
	for d in DIRECTIONS:
		var check = from + d
		# Raycast simple: loop sampai range max
		for k in range(10):
			if check == to: return d
			check += d
	return Vector2i.ZERO

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
		if grid_manager.valid_tiles.has(neighbor) and not board.has(neighbor):
			free += 1
	return free
