# File: res://scripts/CardDB.gd
extends Node
class_name CardDB

# DAFTAR SEMUA KARAKTER DI GAME
# Kita mapping "Nama ID" ke "Script Class"-nya
static var library = {
	"ACROBAT": AcrobatData,
	# ... dst
}

# DAFTAR KARAKTER YANG SUDAH DIAMBIL
# Array string ID unit yang sudah ada di papan / tangan player
static var taken_units : Array = []

# Fungsi untuk mengambil data unit baru
static func get_unit_data(unit_id: String) -> CharacterData:
	if unit_id in taken_units:
		print("Unit ini sudah diambil orang lain!")
		return null
		
	if library.has(unit_id):
		# Bikin instance baru dari scriptnya
		return library[unit_id].new()
	
	return null

# Fungsi saat unit mati/dibuang (dikembalikan ke pool agar bisa diambil lagi - opsional)
static func release_unit(unit_id: String):
	taken_units.erase(unit_id)
