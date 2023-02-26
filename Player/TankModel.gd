extends KinematicBody2D

const WRECK_TSCN = preload("res://Objects/Wreck.tscn")

var s = GameSettings.TANK
var arms= {
		s.BASE_AMMO_TYPE: INF,
}
var player_name = "Player" # defined when spawning
var player_color = Color.blue # defined when spawning

onready var main_n = get_node(Dir.MAIN)
onready var game_n = get_node(Dir.GAME)
onready var battle_timer_n = get_node("/root/Main/BattleTimer")



func setup(player_id, spawn_point, color, _settings):
	s = _settings
	name = str(player_id)
	player_color = color
	position = spawn_point
	

func pick_up_ammo_box(ammo_type) -> bool:
	if !arms.has(ammo_type):
		arms[ammo_type] = 1
		return true
	if arms[ammo_type] < s.MAX_AMMO_TYPES:
		arms[ammo_type] += 1
		return true
	return false

func subtract_ammo_type(ammo_type) -> int:
	if !arms.has(ammo_type):
		print("[Game]: Player ", name, " want to shoot without ammo!")
		return FAILED
	arms[ammo_type] -= 1
	if arms[ammo_type] == 0:
		arms.erase(ammo_type)
	return OK

func set_stance(_position, _rotation):
	position = _position
	$"%Hitbox".rotation = _rotation

func rotate_turret(turret_rotation):
	$"%Turret".rotation = turret_rotation

func die(projectile_name, slayer_id):
	var wreck_inst = WRECK_TSCN.instance()
	var wreck_data = {
		"ID": int(name),
		"Pos": get_global_position(),
		"Rot": $Hitbox.get_global_rotation(),
		"Color": player_color
	}
	wreck_inst.setup(wreck_data)
	game_n.spawn_wreck(wreck_inst)
	Transfer.send_player_destroyed(wreck_data, slayer_id, projectile_name)
	get_parent().remove_child(self)
	battle_timer_n.check_battle_timer()
	queue_free()
