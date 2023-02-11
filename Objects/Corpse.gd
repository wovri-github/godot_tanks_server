extends StaticBody2D

const CORPSE_LIFE_TIME = 20
onready var life_timer_n = $LifeTimer



func setup(data):
	name = str(data.ID)
	set_position(data.Pos)
	set_rotation(data.Rot)

func _ready():
	life_timer_n.start(CORPSE_LIFE_TIME)

func _on_LifeTimer_timeout():
	queue_free()
