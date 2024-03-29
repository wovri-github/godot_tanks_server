extends KinematicBody2D

signal player_destroyed(slayer_id, wreck_data)

var s = GameSettings.Dynamic.Tank
var arms= {
		s.BaseAmmoType: 0,
}
var player_name = "Player" # defined when spawning
var player_color = Color.blue # defined when spawning
var kills: int = 0
var shooting_locked : bool = false
var slot_locked : bool = false
var current_ammo_type = s.BaseAmmoType
onready var ray_cast_n = $"%RayCast2D"


func reload_complete():
	shooting_locked = false

func reset_autoload_timer():
	var load_time = GameSettings.Dynamic.Ammunition[s.BaseAmmoType].Reload * 2
	$BaseTypeAutoloadTimer.start(load_time)

func _on_BaseTypeAutoload():
	if arms[s.BaseAmmoType] < s.BaseAmmoClipSize - 1:
		reset_autoload_timer()
	if arms[s.BaseAmmoType] < s.BaseAmmoClipSize:
		arms[s.BaseAmmoType] += 1

func change_ammo_type(ammo_type) -> bool:
	if slot_locked or !has_ammo_type(ammo_type) or (ammo_type == current_ammo_type):
		return false

	var reload_time = GameSettings.Dynamic.Ammunition[ammo_type].Reload
	var reload_of_prev_ammo = GameSettings.Dynamic.Ammunition[current_ammo_type].Reload
	if !shooting_locked:
		reload_time = max(0.5, reload_time - (reload_of_prev_ammo / 2))
	$ReloadTimer.start(reload_time)
	shooting_locked = true
	current_ammo_type = ammo_type
	return true

func shoot_after_charging(ammo_type) -> bool:
	if !GameSettings.Dynamic.Ammunition[ammo_type].has("ChargeTime") or shooting_locked:
		Logger.sus("[TankModel]: Player "+ name +" want to shoot improper type or while reloading!")
		return false
	slot_locked = true
	shooting_locked = true
	var timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.connect("timeout", self, "call_shoot", [ammo_type])
	timer.start(GameSettings.Dynamic.Ammunition[ammo_type].ChargeTime)
	return true

func call_shoot(ammo_type):
	shooting_locked = false
	slot_locked = false
	get_node("/root/Main/Game").call_deferred("_on_recive_shoot", Data.playerS_stance[int(name)], ammo_type)

func setup(player_id, spawn_point, color):
	name = str(player_id)
	player_color = color
	position = spawn_point
	

func pick_up_ammo_box(ammo_type) -> bool:
	if !arms.has(ammo_type) and arms.size() < s.MaxAmmoTypes:
		arms[ammo_type] = 1
		return true
	elif arms.has(ammo_type):
		arms[ammo_type] += 1
		return true
	return false

func shoot(ammo_type) -> int:
	if !arms.has(ammo_type):
		Logger.sus("[TankModel]: Player " + name + " want to shoot without ammo!")
		return FAILED
	if shooting_locked and !slot_locked: # shoot while reloading
		Logger.sus("[TankModel]: Player " + name + " want to shoot while reloading!")
		return FAILED
	if is_barrel_in_wall():
		Logger.sus("[TankModel]: Player " + name + " want to shoot in wall")
		return FAILED
	slot_locked = false
	arms[ammo_type] -= 1
	if arms[ammo_type] == 0 and ammo_type != s.BaseAmmoType:
		arms.erase(ammo_type)
		ammo_type = s.BaseAmmoType
	shooting_locked = true
	$ReloadTimer.start(GameSettings.Dynamic.Ammunition[ammo_type].Reload)
	if ammo_type == s.BaseAmmoType:
		reset_autoload_timer()
	return OK

func has_ammo_type(ammo_type) -> bool:
	return arms.has(ammo_type)

func is_barrel_in_wall() -> bool:
	ray_cast_n.force_raycast_update()
	if ray_cast_n.is_colliding():
		return true
	return false

func set_stance(_position, _rotation):
	position = _position
	$"%Hitbox".rotation = _rotation

func rotate_turret(turret_rotation):
	$"%Turret".rotation = turret_rotation

func die(kill_event_data={"KillerID" : "", "KilledID" : "", "AT" : NAN, "PName" : ""}):
	var wreck_data = {
		"ID": int(name),
		"Pos": get_global_position(),
		"Rot": $Hitbox.get_global_rotation(),
		"Color": player_color,
		"Kills": kills,
		"LT": GameSettings.Dynamic.Wreck.LifeTime
	}
	get_parent().remove_child(self)
	emit_signal("player_destroyed", kill_event_data.KillerID, wreck_data)
	Transfer.send_player_destroyed(wreck_data, kill_event_data)
	queue_free()



