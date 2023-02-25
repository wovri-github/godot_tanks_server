extends Projectile

const FRAG_TSCN =  preload("res://Shootable/Projectiles/FragBullet.tscn")




func explode():
	for n in range(s.COUNT):
		var param = 2 * PI * n / s.COUNT
		call_deferred("spawn_frag", param)
	die()


func spawn_frag(rotation_param):
	var frag_inst = FRAG_TSCN.instance()
	frag_inst.own_setup(owner_id, global_position, rotation_param, s.FRAG)
	get_parent().add_child(frag_inst)

func _on_LifeTime_timeout():
	explode()
