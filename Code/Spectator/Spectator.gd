extends Camera2D

var s = Settings.SPECATOR.CAMERA
var following = false

func zoom_point(zoom_diff, mouse_position):
	var viewport_size = get_viewport().size
	var previous_zoom = zoom
	if (zoom + zoom_diff) < s.MAX_ZOOM_IN:
		zoom = s.MAX_ZOOM_IN
	else:
		zoom = zoom + zoom_diff
	position += ((viewport_size * 0.5) - mouse_position) * (zoom - previous_zoom)

func _unhandled_input(event):
	if event.is_action_released("zoom_in"):
		zoom_point(Vector2.ONE * -s.ZOOM_SPEED, event.position)
		
	if event.is_action_released("zoom_out"):
		zoom_point(Vector2.ONE * s.ZOOM_SPEED, event.position)
		
	if event.is_action_pressed("left_click"):
		following = true
		
	if event.is_action_released("left_click"):
		following = false
	
	if event is InputEventMouseMotion and following:
		position -= event.relative * zoom

func _process(_delta):
	var velocity = Vector2.ZERO
	velocity.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	velocity.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	if velocity != Vector2.ZERO:
		$Tween.stop(self, "position")
		$Tween.interpolate_property(self, "position", position, position + velocity * s.MOVE_SPEED, 0.1)
		$Tween.start()
