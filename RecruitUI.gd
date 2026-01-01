extends Control

signal card_selected(index)

@onready var buttons = [
	$LeftContainer/VBoxContainer/Card1, 
	$LeftContainer/VBoxContainer/Card2, 
	$LeftContainer/VBoxContainer/Card3
]

var card_texture = preload("res://assets/images/cards.png")
const HFRAMES = 9
const VFRAMES = 3

func _ready():
	for i in range(3):
		buttons[i].pressed.connect(_on_card_clicked.bind(i))
		buttons[i].text = ""
		buttons[i].expand_icon = true 
	hide()

func show_market():
	update_visuals()
	show()

func close_market():
	hide()

func update_visuals():
	# Reset warna tombol jadi normal
	for btn in buttons:
		btn.modulate = Color.WHITE
		
	var tex_w = card_texture.get_width()
	var tex_h = card_texture.get_height()
	var frame_w = tex_w / HFRAMES
	var frame_h = tex_h / VFRAMES
	
	for i in range(3):
		buttons[i].modulate = Color.WHITE 
		
		var unit_id = CardDB.get_market_card_id(i)
		
		if unit_id == "":
			buttons[i].disabled = true
			buttons[i].icon = null
			buttons[i].modulate = Color(0.5, 0.5, 0.5, 0.5) 
		else:
			buttons[i].disabled = false
			# Pastikan modulate putih bersih (kecuali sedang disable)
			buttons[i].modulate = Color.WHITE 
			
			if CardDB.library.has(unit_id):
				var dummy_data = CardDB.library[unit_id].new()
				var col = dummy_data.card_x
				var row = dummy_data.card_y
				
				var atlas = AtlasTexture.new()
				atlas.atlas = card_texture
				atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
				
				buttons[i].icon = atlas
				dummy_data = null

func _on_card_clicked(index):
	# Panggil fungsi highlight visual
	highlight_selected_card(index)
	emit_signal("card_selected", index)

# FUNGSI BARU: VISUALISASI KARTU TERPILIH
func highlight_selected_card(index):
	for i in range(3):
		if i == index:
			buttons[i].modulate = Color(1, 1, 0) # Jadi Kuning (Terpilih)
		else:
			buttons[i].modulate = Color(0.5, 0.5, 0.5) # Jadi Gelap (Tidak terpilih)
			
func set_buttons_active(is_active: bool):
	for btn in buttons:
		# Kita set disabled. 
		# Jika is_active = true, disabled = false (Nyala).
		# Jika is_active = false, disabled = true (Mati).
		btn.disabled = !is_active 
		
		# Opsional: Ubah warna biar kelihatan kalau lagi dikunci
		if is_active:
			btn.modulate = Color.WHITE
		else:
			btn.modulate = Color(0.5, 0.5, 0.5) # Gelap
