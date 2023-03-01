extends Line2D

var s: Dictionary
var ammo_type
var owner_id = NAN
var point : Position2D = null

onready var ray = $RayCast2D
onready var main_n = $"/root/Main"


func setup(player_n : KinematicBody2D, _ammo_type, _settings):
	s = _settings
	owner_id = int(player_n.name)
	ammo_type = _ammo_type
	var _point = player_n.get_node("%LaserSpawn")
	position = _point.global_position

func get_data():
	var pck = Shootable.get_data(
			owner_id, 
			name,
			get_position(),
			get_rotation(),
			null,
			ammo_type
	)
	return pck

func _ready():
	cast_laser()

func cast_laser():
	global_position = point.global_position
	var length_left = s.LaserLength
	
	clear_points()
	add_point(Vector2.ZERO)
	ray.position = Vector2.ZERO
	ray.cast_to = Vector2.UP.rotated(point.global_rotation) * length_left
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
			if owner_id != int(collider.name) and main_n.player_data.has(owner_id):
				main_n.player_data[int(owner_id)].Score.Kills += 1
			collider.die(null, owner_id) # name as null bcs we cant destroy it
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