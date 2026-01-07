extends PanelContainer

# Hubungkan label-label di dalam Tooltip
@onready var name_label = $VBoxContainer/NameLabel
@onready var desc_label = $VBoxContainer/DescLabel

func _ready():
	hide() # Sembunyikan saat mulai

# Fungsi inilah yang dicari oleh GridManager
func show_info(data: CharacterData):
	if data == null: return
	
	name_label.text = data.display_name
	desc_label.text = data.description
	
	show() # Tampilkan panelnya

func hide_info():
	hide() # Sembunyikan panelnya
