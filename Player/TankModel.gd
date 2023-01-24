extends KinematicBody2D

const CORPSE_LIFE_TIME = 20
const MAX_AMMO_TYPES = 3 # including default bullet

onready var main_n = $"/root/Main"
onready var game_n = $"/root/Main/Game"

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

func die(projectile_name, slayer_id):
	var static_body2d = StaticBody2D.new()
	static_body2d.name = name
	static_body2d.position = get_global_position()
	static_body2d.rotation = $Hitbox.get_global_rotation()
	static_body2d.add_to_group("Corpse")
	var lifeTime = Timer.new()
	lifeTime.wait_time = CORPSE_LIFE_TIME
	lifeTime.autostart = true
	static_body2d.add_child(lifeTime)
	lifeTime.connect("timeout",static_body2d,"queue_free")
	Transfer.send_player_destroyed(\
			int(name), static_body2d.position, static_body2d.rotation, slayer_id, projectile_name)
	static_body2d.add_child($Hitbox.duplicate(true))
	game_n.spawn_wall(static_body2d)
	get_parent().remove_child(self)
	main_n.battle_timer_logick()
	queue_free()
