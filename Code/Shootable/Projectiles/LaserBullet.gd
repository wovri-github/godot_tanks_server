extends Projectile

var s = GameSettings.Dynamic.Ammunition[Ammunition.TYPES.LASER_BULLET]


func _ready():
	start_movement(s.Speed)
