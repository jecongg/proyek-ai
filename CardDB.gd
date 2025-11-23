extends Node
class_name CardDB

static var library = {
	"LEADER": LeaderData, # Pastikan LeaderData sudah ada
	"ACROBAT": AcrobatData
}

static var taken_units : Array = []

static func get_unit_data(unit_id: String) -> CharacterData:
	# REVISI: Pengecualian untuk LEADER
	# Leader tidak boleh dicek apakah "sudah diambil", karena P1 dan P2 butuh Leader.
	if unit_id != "LEADER" and unit_id in taken_units:
		print("Unit ini sudah diambil orang lain!")
		return null
		
	if library.has(unit_id):
		var new_data = library[unit_id].new()
		
		# REVISI: Jangan tandai LEADER sebagai "taken"
		if unit_id != "LEADER":
			taken_units.append(unit_id)
			
		return new_data
	
	return null
