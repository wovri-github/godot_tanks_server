extends Projectile

var s = GameSettings.Dynamic.Ammunition[Ammunition.TYPES.FRAG_BOMB]
var frag_tscn = load(Ammunition.shootable[s.Frag.Type])


func _ready():
	start_movement(s.Speed)



func explode():
	for n in range(s.Count):
		var param = 2 * PI * n / s.Count
		call_deferred("spawn_frag", param)
	die()


func spawn_frag(rotation_param):
	var frag_inst = frag_tscn.instance()
	var frag_position = position + 2 * Vector2.UP.rotated(rotation_param)
	frag_inst.setup(general_info.get_info().PlayerID, frag_position, rotation_param, s.Frag.Type, true)
	get_parent().add_child(frag_inst)

func _on_LifeTime_timeout():
	explode()
