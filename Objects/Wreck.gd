extends StaticBody2D

var color = Color.blue # for players joining during battle
onready var s = get_node(Dir.GAME).settings.WRECK
onready var life_timer_n = $LifeTimer


func setup(data):
	name = str(data.ID)
	set_position(data.Pos)
	set_rotation(data.Rot)
	color = data.Color

func _ready():
	print(s.LIFE_TIME)
	life_timer_n.start(s.LIFE_TIME)

func _on_LifeTimer_timeout():
	queue_free()
