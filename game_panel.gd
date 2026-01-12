extends Node2D

# Ambil referensi ke benda-benda penting
@onready var board = $Board
@onready var game_manager = $GameManager
@onready var skip_button = $UILayer/BtnSkip
@onready var skill_button = $UILayer/BtnSkill

func _ready():
	var screen_size = get_viewport_rect().size
	board.position = screen_size / 2
	
	skip_button.pressed.connect(_on_skip_pressed)
	skill_button.pressed.connect(func(): board.toggle_skill_mode())

func _on_skip_pressed():
	if game_manager.current_state == game_manager.State.GAME_OVER:
		return

	if game_manager.current_state == game_manager.State.ACTION_PHASE:
		game_manager.skip_action_phase()
