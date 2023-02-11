extends StaticBody2D

const CORPSE_LIFE_TIME = 20
onready var life_timer_n = $LifeTimer



func setup(data):
	name = str(data.Name)
	set_position(data.Position)
	set_rotation(data.Rotation)

func _ready():
	life_timer_n.start(CORPSE_LIFE_TIME)

func _on_LifeTimer_timeout():
	queue_free()
