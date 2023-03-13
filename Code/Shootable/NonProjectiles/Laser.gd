extends Line2D

var s = GameSettings.Dynamic.Ammunition[Ammunition.TYPES.LASER]
var point : Position2D = null
var point_rotation = 0

var general_info = preload("res://Code/Shootable/ShootableInfo.gd").new()
onready var death_time = OS.get_ticks_msec() + 10_000
onready var ray = $RayCast2D
onready var main_n = $"/root/Main"


func setup(_owner_id, _spawn_point, _spawn_rotation, _ammo_type):
	general_info.set_info(_owner_id, name, _ammo_type)
	position = _spawn_point
	point_rotation = _spawn_rotation

func get_data():
	var projectile_info = {
		"P": get_position(),
		"R": point_rotation,
		"DT": death_time 
	}
	projectile_info.merge(general_info.get_info())
	return projectile_info


func _ready():
	cast_laser()

func cast_laser():
	#global_position = point.global_position
	var length_left = s.Length
	
	clear_points()
	add_point(Vector2.ZERO)
	ray.position = Vector2.ZERO
	ray.cast_to = Vector2.UP.rotated(point_rotation) * length_left
	ray.force_raycast_update()
	
	for _i in range(s.MaxBounces):	# limit bounces
		
		if !ray.is_colliding():
			add_point(ray.cast_to + ray.position)
			break
			
		var collider = ray.get_collider()
		var collision_point = ray.get_collision_point()
		var collision_normal = ray.get_collision_normal()
		
		add_point(to_local(ray.get_collision_point()))
		
		if collider.is_in_group("Players"):
			collider.die({"KillerID" : str(general_info.get_info().PlayerID), "KilledID" : collider.name, "AT" : general_info.get_info().AT, "PName" : null}) # name as null bcs we cant destroy it
			break
		
		if collider.is_in_group("Corpse"):
			break
		
		if collision_normal == Vector2.ZERO:
			break
			
		length_left -= ray.to_local(collision_point).length()
		ray.cast_to = ray.cast_to.bounce(collision_normal).normalized() * length_left
		ray.position = to_local(collision_point) + ray.cast_to.normalized()
		# move ray position a bit from collision point not to collide with the same point twice
		
		ray.force_raycast_update()


func _on_LifeTime_timeout():
	queue_free()
