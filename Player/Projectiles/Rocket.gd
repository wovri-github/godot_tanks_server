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
		return
	for player in get_tree().get_nodes_in_group("Players"):
		if target == null:
			target = player
		if player.global_position.distance_to(self.global_position) < \
				target.global_position.distance_to(self.global_position):
			target = player
	if is_instance_valid(target):
		navigation_agent.set_target_location(target.global_position)
		var move_direction = position.direction_to(navigation_agent.get_next_location())
		var velocity = move_direction * s.FOLLOW_SPEED
		look_at(navigation_agent.get_next_location())
		set_linear_velocity(velocity) 
		navigation_agent.set_velocity(velocity)
