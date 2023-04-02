extends Projectile

var target : KinematicBody2D = null
onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
var started_targeting = false

var s = GameSettings.Dynamic.Ammunition[Ammunition.TYPES.ROCKET]

var owner_color = Color.white
var target_color = Color.white


func _ready():
	var player_id = general_info.get_info().PlayerID
	var player_n = get_node_or_null("/root/Main/Game/Players/" + str(player_id))
	if player_n != null:
		owner_color = player_n.player_color

func get_stance() -> Dictionary:
	var stance = {
		"ID": name,
		"P": position,
		"R": rotation,
		"OC": owner_color,
		"TC": target_color
	}
	return stance


func _on_StartTargeting_timeout():
	started_targeting = true

func _integrate_forces(state):
	if !started_targeting:
		return
	for player in get_tree().get_nodes_in_group("Players"):
		if target == null:
			target = player
			target_color = player.player_color
		if !is_instance_valid(target) or !target.is_inside_tree():
			target = null
			target_color = Color.white
			continue
		if !is_instance_valid(player):
			continue
		if player.global_position.distance_to(self.global_position) < \
				target.global_position.distance_to(self.global_position):
			target = player
			target_color = player.player_color
	if is_instance_valid(target):
		navigation_agent.set_target_location(target.global_position)
		var move_direction = position.direction_to(navigation_agent.get_next_location())
		var velocity = move_direction * s.FollowSpeed
		set_linear_velocity(velocity) 
		navigation_agent.set_velocity(velocity)

func _physics_process(delta):
	if is_instance_valid(target):
		var rot = navigation_agent.get_next_location().angle_to_point(position)
		rotation = lerp_angle(rotation, rot, delta * 8)
	else:
		rotation = linear_velocity.angle()
