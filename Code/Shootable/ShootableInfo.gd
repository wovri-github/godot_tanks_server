extends GDScript

var is_frag: bool
var info: Dictionary = {
	"PlayerID": null,
	"AT": null,
}



func set_info(_owner_id, _name, _ammo_type, _is_frag = false):
	info.PlayerID = _owner_id
	info.AT = _ammo_type
	info.ID = _name
	is_frag = _is_frag

func get_info() -> Dictionary:
	return info

func get_kill_data(killed_id) -> Dictionary:
	return {}#TODO
