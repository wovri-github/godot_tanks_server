extends Projectile

var s = GameSettings.Dynamic.Ammunition[Ammunition.TYPES.FRAG_BOMB]
var frag_tscn = load(Ammunition.shootable[s.Frag.Type])

func _ready():
	position = spawn_point
	var velocity = Vector2.UP.rotated(spawn_rotation) * s.Speed
	set_linear_velocity(velocity)



func explode():
	for n in range(s.Count):
		var param = 2 * PI * n / s.Count
		call_deferred("spawn_frag", param)
	die()


func spawn_frag(rotation_param):
	var frag_inst = frag_tscn.instance()
	var frag_position = position + 2 * Vector2.UP.rotated(rotation_param)
	frag_inst.setup(owner_id, frag_position, rotation_param, s.Frag.Type)
	frag_inst.get_node("LifeTime").wait_time *= s.Frag.LifetimeMultiplayer
	frag_inst.get_node("CollisionShape2D").scale *= s.Frag.Scale
	frag_inst.is_frag_bomb_frag = true
	get_parent().add_child(frag_inst)

func _on_LifeTime_timeout():
	explode()
