extends KinematicBody2D

const MAX_AMMO_TYPES = 3 # including default bullet
const CORPSE_TSCN = preload("res://Objects/Corpse.tscn")

onready var main_n = $"/root/Main"
onready var game_n = $"/root/Main/Game"
onready var battle_timer_n = get_node("/root/Main/BattleTimer")

var special_ammo = [
	 {"type" : Ammunition.TYPES.BULLET, "amount" : INF}
]
var player_name = "Player" # defined when spawning

func pick_up_ammo_box(type):
	var type_slot = {}
	for slot in special_ammo.size():
		type_slot[special_ammo[slot].type] = slot
	if type_slot.has(type):
		special_ammo[type_slot[type]].amount += 1
		return true
	elif special_ammo.size() < MAX_AMMO_TYPES:
		special_ammo.push_back({"type" : int(type), "amount" : 1})
		return true
	return false

func set_stance(_position, _rotation):
	position = _position
	$"%Hitbox".rotation = _rotation

func rotate_turret(turret_rotation):
	$"%Turret".rotation = turret_rotation

func die(projectile_name, slayer_id): #TODO
	var corpse_inst = CORPSE_TSCN.instance()
	var corpse_data = {
		"ID": int(name),
		"Pos": get_global_position(),
		"Rot": $Hitbox.get_global_rotation()
	}
	corpse_inst.setup(corpse_data)
	game_n.spawn_wall(corpse_inst)
	Transfer.send_player_destroyed(corpse_data, slayer_id, projectile_name)
	get_parent().remove_child(self)
	battle_timer_n.calculate_time()
	queue_free()
