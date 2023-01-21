tool
extends Area2D

export(Ammunition.TYPES) var type = Ammunition.TYPES.ROCKET setget set_type
onready var sprite = $"%TypeSprite"

func _ready():
	if !Engine.editor_hint:
		sprite.texture = Ammunition.get_box_texture(type)

func set_type(_type):
	type = _type
	if Engine.editor_hint and sprite != null:
		sprite.texture = Ammunition.get_box_texture(type)

func _on_AmmoBox_body_entered(body):
	if !body.is_in_group("Players"):
		return
	if body.pick_up_ammo_box(type):
			queue_free()


