extends Node
class_name CardDB

# --- DATA LIBRARY ---
# Daftar semua script karakter yang ada
# Pastikan script AcrobatData, LeaderData, dll sudah ada class_name-nya
static var library = {
	"LEADER": LeaderData,
	"ACROBAT": AcrobatData,
	"RIDER": RiderData,
	"ASSASSIN": AssassinData,
	"ARCHER": ArcherData,
	"ROYAL_GUARD": RoyalGuardData,
	"VIZIER": VizierData,
	"WANDERER": WandererData,
	"BREWMASTER": BrewmasterData,
	"BRUISER": BruiserData,
	"CLAW_LAUNCHER": ClawLauncherData,
	"ILLUSIONIST": IllusionistData,
	"MANIPULATOR": ManipulatorData,
	"JAILER": JailerData,
	"PROTECTOR": ProtectorData,
	"NEMESIS": NemesisData,
	"HERMIT": HermitData,
	"CUB": CubData
}

# --- DECK MANAGEMENT ---
static var available_deck : Array = [] # Tumpukan kartu tertutup
static var market_cards : Array = []   # 3 Kartu terbuka
static var taken_units : Array = []    # Kartu yang sudah diambil player

# --- FUNGSI 1: SETUP AWAL ---
static func initialize_deck():
	available_deck.clear()
	market_cards.clear()
	taken_units.clear()
	
	# Masukkan unit ke deck
	for key in library.keys():
		if key != "LEADER" and key != "CUB": 
			# CUKUP SEKALI SAJA biar unik
			available_deck.append(key)
			
	available_deck.shuffle()
	refill_market()

# --- FUNGSI 2: URUS PASAR (MARKET) ---
static func refill_market():
	# Isi pasar sampai ada 3 kartu (selama deck masih ada sisa)
	while market_cards.size() < 3 and available_deck.size() > 0:
		var new_card = available_deck.pop_front()
		market_cards.append(new_card)
		print("Market Refilled: ", new_card)

static func get_market_card_id(index: int) -> String:
	if index >= 0 and index < market_cards.size():
		return market_cards[index]
	return "" # Kosong/Habis

# Di dalam CardDB.gd

static func pick_card_from_market(index: int) -> String:
	if index < 0 or index >= market_cards.size(): return ""
	
	var picked_id = market_cards[index]
	
	# --- HAPUS BAGIAN INI (Kommentari atau Delete) ---
	# if picked_id != "LEADER":
	# 	taken_units.append(picked_id)
	# -------------------------------------------------
	# Alasannya: Biar GridManager yang nandain taken saat spawn. 
	# Kalau ditandain di sini, GridManager bakal ditolak saat minta data.
	
	# GANTI SLOT DENGAN KARTU BARU
	if available_deck.size() > 0:
		var new_card = available_deck.pop_front()
		market_cards[index] = new_card
		print("Slot ", index, " diganti dengan ", new_card)
	else:
		market_cards[index] = "" 
	
	return picked_id

# --- FUNGSI 3: SPAWN DATA (Yang tadi Error) ---
static func get_unit_data(unit_id: String) -> CharacterData:
	# Pengecualian: Leader tidak dicek "Taken" (karena ada 2)
	if unit_id != "LEADER" and unit_id in taken_units:
		print("Unit ini sudah diambil orang lain!")
		return null
	
	if library.has(unit_id):
		var new_data = library[unit_id].new()
		
		# Tandai unit sebagai "Taken" (Kecuali Leader)
		if unit_id != "LEADER":
			taken_units.append(unit_id)
			
		return new_data
	
	print("Error: Unit ID '", unit_id, "' tidak ditemukan di Library.")
	return null
