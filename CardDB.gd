extends Node
class_name CardDB

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

static var available_deck : Array = []
static var market_cards : Array = []
static var taken_units : Array = []

static func initialize_deck():
	available_deck.clear()
	market_cards.clear()
	taken_units.clear()
	for key in library.keys():
		if key != "LEADER" and key != "CUB": 
			available_deck.append(key)
	available_deck.shuffle()
	refill_market()

static func refill_market():
	while market_cards.size() < 3 and available_deck.size() > 0:
		market_cards.append(available_deck.pop_front())

static func get_market_card_id(index: int) -> String:
	if index >= 0 and index < market_cards.size():
		return market_cards[index]
	return ""

static func pick_card_from_market(index: int) -> String:
	if index < 0 or index >= market_cards.size(): return ""
	var picked_id = market_cards[index]
	if available_deck.size() > 0:
		market_cards[index] = available_deck.pop_front()
	else:
		market_cards.remove_at(index)
	return picked_id

# FUNGSI PERBAIKAN: Jangan tandai "Taken" di sini jika hanya untuk preview UI
static func get_unit_data(unit_id: String) -> CharacterData:
	# JANGAN cek 'taken_units' di sini agar UI bisa menampilkan icon.
	# Pengecekan 'taken_units' hanya dilakukan saat unit benar-benar diletakkan di papan.
	if library.has(unit_id):
		return library[unit_id].new()
	return null
