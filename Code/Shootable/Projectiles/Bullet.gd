extends Projectile

var s = GameSettings.Dynamic.Ammunition[Ammunition.TYPES.BULLET]

func _ready():
	start_movement(s.Speed)

