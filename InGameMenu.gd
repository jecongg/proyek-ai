extends Control

# Referensi Node (Perhatikan path-nya berubah karena ada Overlay)
@onready var overlay = $Overlay
@onready var menu_box = $Overlay/MenuBox
@onready var confirm_dialog = $Overlay/ConfirmDialog
@onready var title_label = $Overlay/MenuBox/VBoxContainer/TitleLabel
@onready var btn_resume = $Overlay/MenuBox/VBoxContainer/BtnResume
@onready var btn_pause = $BtnPause 

var pending_action = "" 

func _ready():
	# Pastikan Root Node (Self) SELALU NYALA
	visible = true 
	
	# Yang kita sembunyikan cuma Overlay-nya
	overlay.hide()
	confirm_dialog.hide()
	
	# Hubungkan Tombol (Sama seperti sebelumnya)
	btn_pause.pressed.connect(open_pause_menu)
	
	# Perhatikan path tombol di dalam Overlay
	$Overlay/MenuBox/VBoxContainer/BtnResume.pressed.connect(close_menu)
	$Overlay/MenuBox/VBoxContainer/BtnRetry.pressed.connect(on_retry_pressed)
	$Overlay/MenuBox/VBoxContainer/BtnMenu.pressed.connect(on_menu_pressed)
	
	$Overlay/ConfirmDialog/VBoxContainer/HBoxContainer/BtnYes.pressed.connect(on_confirm_yes)
	$Overlay/ConfirmDialog/VBoxContainer/HBoxContainer/BtnNo.pressed.connect(on_confirm_no)

# --- FUNGSI BUKA/TUTUP MENU ---
func open_pause_menu():
	overlay.show()      # Munculkan Overlay
	menu_box.show()
	confirm_dialog.hide()
	
	title_label.text = "PAUSED"
	btn_resume.visible = true 
	btn_pause.visible = false # Sembunyikan tombol pause kecil biar bersih

func open_game_over_menu(winner_id: int):
	overlay.show()      # Munculkan Overlay
	menu_box.show()
	confirm_dialog.hide()
	
	title_label.text = "PLAYER " + str(winner_id) + " WINS!"
	btn_resume.visible = false 
	btn_pause.visible = false

func close_menu():
	overlay.hide()      # Sembunyikan Overlay
	btn_pause.visible = true # Munculkan lagi tombol pause kecil

# --- LOGIKA KONFIRMASI (Sama) ---
func on_retry_pressed():
	pending_action = "retry"
	show_confirmation("Restart Game?")

func on_menu_pressed():
	pending_action = "menu"
	show_confirmation("Quit to Menu?")

func show_confirmation(text: String):
	menu_box.hide() 
	confirm_dialog.show()
	$Overlay/ConfirmDialog/VBoxContainer/Label.text = text

func on_confirm_no():
	confirm_dialog.hide()
	menu_box.show() 
	pending_action = ""

func on_confirm_yes():
	if pending_action == "retry":
		get_tree().reload_current_scene()
	elif pending_action == "menu":
		# Ganti path ini ke scene main menu kamu
		get_tree().change_scene_to_file("res://MainMenu.tscn")
