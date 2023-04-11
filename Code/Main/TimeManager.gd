extends Timer

signal phase_changed(phase)

const phase_list: Array = ["BegBattle", "Battle", "EndBattle", "Upgrade"]
enum {BegBattle, Battle}
const phase_time = {
	"BegBattle": 2,
	"Battle": 0, 
	"EndBattle": 3, 
	"Upgrade": 4,
}
export (String) var phase = null

#func _ready():
#	print(BegBattle)

