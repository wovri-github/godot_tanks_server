extends Projectile

onready var collision_shape = $CollisionShape2D
onready var life_time = $LifeTime


func own_setup(owner_id, _position, _rotation, _settings):
	s = _settings
	owner_id = int(owner_id)
	var velocity = Vector2.UP.rotated(_rotation)
	position = _position + 1 * velocity # separate frags from each other
	set_linear_velocity(velocity * s.SPEED)


func _ready():
	life_time.wait_time *= s.LIFETIME_MULTIPLIER
	collision_shape.set_scale(collision_shape.scale * s.SCALE)
	is_frag_bomb_frag = true

