extends Line2D

const LASER_LENGTH = 2000
const MAX_BOUNCES = 15
const MAX_WIDTH = 5

onready var ray = $RayCast2D

var player_path = NodePath("")
var point : Position2D = null


func setup(player : KinematicBody2D) -> Dictionary:
	point = player.get_node("%LaserSpawn")
	player_path = player.get_path()
	return {"SP": point.global_position, "R": point.global_rotation}
	
func _ready():
	cast_laser()

func cast_laser():
	global_position = point.global_position
	var length_left = LASER_LENGTH
	
	clear_points()
	add_point(Vector2.ZERO)
	ray.position = Vector2.ZERO
	ray.cast_to = Vector2.UP.rotated(point.global_rotation) * length_left
	ray.force_raycast_update()
	
	for i in range(MAX_BOUNCES):	# limit bounces
		
		if !ray.is_colliding():
			add_point(ray.cast_to + ray.position)
			break
			
		var collider = ray.get_collider()
		var collision_point = ray.get_collision_point()
		var collision_normal = ray.get_collision_normal()
		
		add_point(to_local(ray.get_collision_point()))
		
		if collider.is_in_group("Players"):
			var player = get_node_or_null(player_path)
			if !(player == null):
				player.score += 1
				Transfer.send_score_update(player.name, player.score)
			collider.die(name)
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
