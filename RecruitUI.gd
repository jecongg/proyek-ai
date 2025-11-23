extends Control

signal card_selected(index)

# HAPUS referensi deck_image
@onready var buttons = [
	$LeftContainer/VBoxContainer/Card1, 
	$LeftContainer/VBoxContainer/Card2, 
	$LeftContainer/VBoxContainer/Card3
]

# Load Texture Kartu
var card_texture = preload("res://assets/images/cards.png")

# Setting Frame
const HFRAMES = 9
const VFRAMES = 3

func _ready():
	# Setup tombol
	for i in range(3):
		buttons[i].pressed.connect(_on_card_clicked.bind(i))
		buttons[i].text = ""
		buttons[i].expand_icon = true 
		
		# Opsional: Pastikan ukuran tombol konsisten
		# buttons[i].custom_minimum_size = Vector2(200, 300) 

	# KODE SET DECK IMAGE DIHAPUS DI SINI

	hide()

func show_market():
	update_visuals()
	show()

func update_visuals():
	# Hitung ukuran frame otomatis
	var tex_w = card_texture.get_width()
	var tex_h = card_texture.get_height()
	var frame_w = tex_w / HFRAMES
	var frame_h = tex_h / VFRAMES
	
	for i in range(3):
		var unit_id = CardDB.get_market_card_id(i)
		
		if unit_id == "":
			buttons[i].disabled = true
			buttons[i].icon = null
			buttons[i].modulate = Color(0.5, 0.5, 0.5, 0.5) 
		else:
			buttons[i].disabled = false
			buttons[i].modulate = Color.WHITE
			
			if CardDB.library.has(unit_id):
				var dummy_data = CardDB.library[unit_id].new()
				
				# --- LANGSUNG PAKAI X DAN Y ---
				var col = dummy_data.card_x
				var row = dummy_data.card_y
				
				var atlas = AtlasTexture.new()
				atlas.atlas = card_texture
				
				# RUMUSNYA JADI SEDERHANA:
				# (Kolom * Lebar, Baris * Tinggi, Lebar, Tinggi)
				atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
				
				buttons[i].icon = atlas
				dummy_data = null

func _on_card_clicked(index):
	emit_signal("card_selected", index)
	hide()
