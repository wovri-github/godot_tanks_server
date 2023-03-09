extends Projectile

var s = GameSettings.Dynamic.Ammunition[Ammunition.TYPES.LASER_BULLET]

func _ready():
	position = spawn_point
	var velocity = Vector2.UP.rotated(spawn_rotation) * s.Speed
	set_linear_velocity(velocity)
