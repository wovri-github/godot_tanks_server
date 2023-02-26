tool
extends Area2D

export(Ammunition.TYPES) var type = Ammunition.TYPES.ROCKET setget set_type



func set_type(_type):
	if Engine.editor_hint:
		var sprite = $"%TypeSprite"
		type = _type
		sprite.texture = Ammunition.get_box_texture(type)

func _on_AmmoBox_body_entered(player):
	player.special_ammo[type] += 1
	queue_free()


