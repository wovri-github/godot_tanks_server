extends StaticBody2D

var s = Settings.TANK
onready var life_timer_n = $LifeTimer



func setup(data):
	name = str(data.ID)
	set_position(data.Pos)
	set_rotation(data.Rot)

func _ready():
	life_timer_n.start(s.CORPSE_LIFE_TIME)

func _on_LifeTimer_timeout():
	queue_free()
