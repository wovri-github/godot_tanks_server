extends Projectile

var target : KinematicBody2D = null
onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
var started_targeting = false
var x = -0.5

var s = GameSettings.Dynamic.Ammunition[Ammunition.TYPES.ROCKET]


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
		if !is_instance_valid(target) or !target.is_inside_tree():
			target = null
			continue
		if !is_instance_valid(player):
			continue
		if player.global_position.distance_to(self.global_position) < \
				target.global_position.distance_to(self.global_position):
			target = player
	if is_instance_valid(target):
		x += 0.05
		if x >= 0.5:
			x = -0.5
		navigation_agent.set_target_location(target.global_position)
		var move_direction = (position.direction_to(navigation_agent.get_next_location())).rotated(x*2)
		var velocity = move_direction * s.FollowSpeed
		look_at(navigation_agent.get_next_location())
		set_linear_velocity(velocity) 
		navigation_agent.set_velocity(velocity)
