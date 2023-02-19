extends Projectile

var s = Settings.AMMUNITION.ROCKET
var target : KinematicBody2D = null
onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
var started_targeting = false


func get_stance() -> Dictionary:
	var stance = {
		"ID": name,
		"P": position,
		"R": rotation,
	}
	return stance


func _on_StartTargeting_timeout():
	started_targeting = true

func _integrate_forces(_state):
	if !started_targeting:
#		rotation = linear_velocity.angle()
		return
	for player in get_tree().get_nodes_in_group("Players"):
		if target == null:
			target = player
		if player.global_position.distance_to(self.global_position) < \
				target.global_position.distance_to(self.global_position):
			target = player
	if target != null:
		navigation_agent.set_target_location(target.global_position)
		var move_direction = position.direction_to(navigation_agent.get_next_location())
		var velocity = move_direction * s.FOLLOW_SPEED
		set_linear_velocity(velocity) 
		navigation_agent.set_velocity(velocity)
#	rotation = global_transform.origin.angle_to_point(target.global_transform.origin) + PI
#	linear_velocity = linear_velocity.linear_interpolate(\
#			(target.global_transform.origin.direction_to(global_transform.origin) * -s.SPEED), \
#			_state.get_step()*s.FOLLOW_SPEED)

#	var taransform = _state.get_transform()
#	taransform.origin = navigation_agent.get_next_location()
#	_state.set_transform(taransform)
