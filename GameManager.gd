extends Node

# Hubungkan ke Board (Karena GameManager adalah saudara Board)
@onready var grid_manager = $"../Board" 

func _ready():
	# Tunggu sebentar biar Board siap
	await get_tree().process_frame
	start_game()

func start_game():
	print("Game Dimulai!")
	
	# Pastikan kamu sudah bikin script LeaderData dan daftarkan di CardDB dengan nama "LEADER"
	# Jika belum punya, kode ini akan error/print gagal.
	grid_manager.spawn_unit_by_id("LEADER", grid_manager.p1_leader_start, 1)
	grid_manager.spawn_unit_by_id("LEADER", grid_manager.p2_leader_start, 2)
